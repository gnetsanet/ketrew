(** The error-monad embedded in a [Lwt.t]. *)

include Pvem.DEFERRED_RESULT
  with type 'a deferred = 'a Lwt.t
   and type ('ok, 'error) t = ('ok, 'error) Pvem.Result.t Lwt.t

val sleep : float -> (unit, [> `Exn of exn ]) t

val pick_and_cancel: ('a, 'error) t list -> ('a, 'error) t

val asynchronously: (unit -> (unit, unit) t) -> unit
(** Launch a function asynchronously the [unit] return type is meant
    to force you treat all errors within that function. *)
