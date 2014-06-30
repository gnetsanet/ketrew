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

open Ketrew_pervasives

module Path = Ketrew_path

module Host = Ketrew_host

module Volume = struct

  open Ketrew_gen_base_v0_t
  type structure = volume_structure =
    | File of string
    | Directory of (string * structure list)

  type t = volume = {
    host: Host.t;
    root: Path.absolute_directory;
    structure: structure;
  }
  let create ~host ~root structure = {host; root; structure}
  let file s = File s
  let dir name contents = Directory (name, contents)

  let rec all_structure_paths : 
    type any. structure -> <kind: any; relativity: Path.relative > Path.t list =
    fun s ->
    match s with
    | File s -> [Path.relative_file_exn s |> Path.any_kind ]
    | Directory (name, children) ->
      let children_paths = 
        List.concat_map ~f:all_structure_paths children in
      let this_one = Path.relative_directory_exn name in
      (this_one |> Path.any_kind) :: List.map ~f:(Path.concat this_one) children_paths

  let all_paths t: <kind: 'any; relativity: Path.absolute> Path.t list =
    List.map ~f:(Path.concat t.root) (all_structure_paths t.structure)

  let exists t =
    let paths = all_paths t in
    Host.do_files_exist t.host paths

  let log {host; root; structure} =
    Log.(s "Vol" % parens (Host.log host % s":" % s (Path.to_string root)))
  let to_string_hum v =
    Log.to_long_string (log v)
end

module Value = struct

  type t = Ketrew_gen_base_v0_t.artifact_value

  let log = 
    let log_variant name v =
      Log.(brakets (s name % if v <> empty then sp % v else empty)) in
    function
  | `Number fl ->  log_variant "Number" Log.(f fl)
  | `String str -> log_variant "String " Log.(s str)
  | `Unit -> log_variant "Unit " Log.empty
  
  let unit = `Unit
end



type t = Ketrew_gen_base_v0_t.artifact

let log = function
| `Volume v -> Volume.log v
| `Value v -> Value.log v


