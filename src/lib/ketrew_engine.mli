(**************************************************************************)
(*  Copyright 2014, Sebastien Mondet <seb@mondet.org>                     *)
(*                                                                        *)
(*  Licensed under the Apache License, Version 2.0 (the "License");       *)
(*  you may not use this file except in compliance with the License.      *)
(*  You may obtain a copy of the License at                               *)
(*                                                                        *)
(*      http://www.apache.org/licenses/LICENSE-2.0                        *)
(*                                                                        *)
(*  Unless required by applicable law or agreed to in writing, software   *)
(*  distributed under the License is distributed on an "AS IS" BASIS,     *)
(*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or       *)
(*  implied.  See the License for the specific language governing         *)
(*  permissions and limitations under the License.                        *)
(**************************************************************************)

(** The engine of the actual Workflow Engine. *)

open Ketrew_pervasives

type t
(** The contents of the application engine. *)

val with_engine: 
  configuration:Ketrew_configuration.engine ->
  (engine:t ->
   (unit, [> `Database of Ketrew_database.error 
          | `Failure of string
          | `Database_unavailable of Ketrew_target.id
          | `Dyn_plugin of
               [> `Dynlink_error of Dynlink.error | `Findlib of exn ]
          ] as 'merge_error) Deferred_result.t) ->
  (unit, 'merge_error) Deferred_result.t
(** Create a {!engine.t}, run the function passed as argument, and properly dispose of it. *)

val load: 
  configuration:Ketrew_configuration.engine ->
  (t,
   [> `Database of Ketrew_database.error 
   | `Failure of string
   | `Dyn_plugin of
        [> `Dynlink_error of Dynlink.error | `Findlib of exn ]
   ]) Deferred_result.t

val unload: t -> 
  (unit, [>
      | `Database_unavailable of Ketrew_target.id
      | `Database of [> `Act of Ketrew_database.action | `Close ] * string 
    ]) Deferred_result.t

val database: t -> (Ketrew_database.t,
                    [> `Database of [> `Load of string ] * string ]) Deferred_result.t
(** Get the database handle managed by the engine. *)

val configuration: t -> Ketrew_configuration.engine
(** Retrieve the configuration. *)

val add_targets :
  t ->
  Ketrew_target.t list ->
  (unit,
   [> `Database of Ketrew_database.error
   | `Database_unavailable of Ketrew_target.id
   | `Missing_data of Ketrew_target.id
   | `Target of [> `Deserilization of string ]
   | `Persistent_state of [> `Deserilization of string ] ])
  Deferred_result.t
(** Add a list of targets to the engine. *)

val get_target: t -> Unique_id.t ->
  (Ketrew_target.t,
   [> `Database of Ketrew_database.error
   | `Persistent_state of [> `Deserilization of string ]
   | `Missing_data of string
   | `Target of [> `Deserilization of string ] ])
    Deferred_result.t
(** Get a target from its id. *)

val current_targets :
  t ->
  (Ketrew_target.t list,
   [> `Database of Ketrew_database.error
    | `IO of
        [> `Read_file_exn of string * exn | `Write_file_exn of string * exn ]
    | `Missing_data of Ketrew_target.id
    | `Persistent_state of [> `Deserilization of string ]
    | `System of [> `File_info of string ] * [> `Exn of exn ]
    | `Target of [> `Deserilization of string ] ])
  Deferred_result.t
(** Get the list of targets currently handled. *)
  
val archived_targets :
  t ->
  (Ketrew_target.t list,
   [> `Database of Ketrew_database.error
    | `IO of
        [> `Read_file_exn of string * exn | `Write_file_exn of string * exn ]
    | `Missing_data of Ketrew_target.id
    | `Persistent_state of [> `Deserilization of string ]
    | `System of [> `File_info of string ] * [> `Exn of exn ]
    | `Target of [> `Deserilization of string ] ])
  Deferred_result.t
(** Get the list of targets that have been archived. *)

val is_archived: t -> Unique_id.t -> 
  (bool, 
   [> `Database of Ketrew_database.error
   | `Missing_data of Ketrew_target.id
   | `Persistent_state of [> `Deserilization of string ]
   | `Target of [> `Deserilization of string ] ])
    Deferred_result.t
(** Check whether a target is in the “archive”. *)
  
type happening = Ketrew_gen_base_v0.Happening.t
(** Structured log of what can happen during {!step} or {!kill}. *)

val what_happened_to_string : happening -> string
(** Transform an item of the result of {!step} to a human-readable string. *)

val log_what_happened : happening -> Log.t
(** Transform a {!happening} into {!Log.t} document. *)

val step :
  t ->
  (happening list,
   [> `Database of Ketrew_database.error
   | `Database_unavailable of Ketrew_target.id
   | `Host of _ Ketrew_host.Error.non_zero_execution
   | `Volume of [> `No_size of Log.t]
   | `IO of
        [> `Read_file_exn of string * exn | `Write_file_exn of string * exn ]
   | `Missing_data of Ketrew_target.id
   | `Persistent_state of [> `Deserilization of string ]
   | `System of [> `File_info of string ] * [> `Exn of exn ]
   | `Target of [> `Deserilization of string ] ])
    Deferred_result.t
(** Run one step of the engine; [step] returns a list of “things that
    happened”. *)

val fix_point: t ->
  ([ `Steps of int] * happening list list,
   [> `Database of Ketrew_database.error
   | `Database_unavailable of Ketrew_target.id
   | `Host of _ Ketrew_host.Error.non_zero_execution
   | `Volume of [> `No_size of Log.t]
   | `IO of
        [> `Read_file_exn of string * exn | `Write_file_exn of string * exn ]
   | `Missing_data of Ketrew_target.id
   | `Persistent_state of [> `Deserilization of string ]
   | `System of [> `File_info of string ] * [> `Exn of exn ]
   | `Target of [> `Deserilization of string ] ])
    Deferred_result.t
(** Run {!step} many times until nothing happens or nothing “new” happens. *)

val get_status : t -> Ketrew_target.id ->
  (Ketrew_target.workflow_state,
   [> `Database of Ketrew_database.error
   | `IO of
        [> `Read_file_exn of string * exn | `Write_file_exn of string * exn ]
   | `Missing_data of string
   | `Persistent_state of [> `Deserilization of string ]
   | `System of [> `File_info of string ] * [> `Exn of exn ]
   | `Target of [> `Deserilization of string ] ])
    Deferred_result.t
(** Get the state description of a given target (by “id”). *)

val kill:  t -> id:Ketrew_target.id ->
  (happening list,
   [> `Database of Ketrew_database.error
   | `Failed_to_kill of string
   | `Database_unavailable of string
   | `IO of
        [> `Read_file_exn of string * exn
        | `Write_file_exn of string * exn ]
   | `Missing_data of string
   | `Not_implemented of string
   | `Persistent_state of [> `Deserilization of string ]
   | `System of [> `File_info of string ] * [> `Exn of exn ]
   | `Target of [> `Deserilization of string ] ]) Deferred_result.t
(** Kill a target *)

val archive_target: t ->
  Ketrew_target.id ->
  (happening list,
   [> `Database of Ketrew_database.error
   | `Database_unavailable of Ketrew_target.id
   | `Missing_data of Ketrew_target.id
   | `Target of [> `Deserilization of string ]
   | `Persistent_state of [> `Deserilization of string ] ])
    Deferred_result.t
(** Move a target to the “archived” list. *)

val restart_target: t -> Ketrew_target.id -> 
  (happening list, 
   [> `Database of Ketrew_database.error
   | `Database_unavailable of Ketrew_target.id
   | `Missing_data of Ketrew_target.id
   | `Persistent_state of [> `Deserilization of string ]
   | `Target of [> `Deserilization of string ] ]) Deferred_result.t
(** Make new activated targets out of a given target and its “transitive
    reverse dependencies” *)

(** A module to manipulate the graph of dependencies. *)
module Target_graph: sig

  type engine = t
  (** An alias for {!t}, the engine. *)

  type t
  (** The actual representation of the Graph. *)

  val get_current: engine:engine -> 
    (t,
     [> `Database of Ketrew_database.error
     | `Missing_data of Ketrew_target.id
     | `Persistent_state of [> `Deserilization of string ]
     | `Target of [> `Deserilization of string ] ]) Deferred_result.t
  (** Do like {!current_targets} as a graph, hence this may also pull
      “archived” targets, through dependencies. *)

  val log: t -> Log.t
  (** Get a displayable {!Log.t} for the graph. *)

  val targets_to_clean_up: t -> [`Hard | `Soft] ->
    [ `To_kill of Ketrew_target.id list ] * [ `To_archive of Ketrew_target.id list ]
end

module Measure: sig

  val incomming_request:
    t ->
    connection_id:Cohttp.Connection.t ->
    request:Cohttp.Request.t ->
    unit
  val end_of_request:
    t ->
    connection_id:Cohttp.Connection.t ->
    request:Cohttp.Request.t ->
    unit
  val tag: t -> string -> unit
end
module Measurements: sig

  val flush: t ->
    (unit, [>
        | `Database of Ketrew_database.error
        | `Database_unavailable of Ketrew_target.id
      ]) Deferred_result.t

end