(**************************************************************************)
(*    Copyright 2014, 2015:                                               *)
(*          Sebastien Mondet <seb@mondet.org>,                            *)
(*          Leonid Rozenberg <leonidr@gmail.com>,                         *)
(*          Arun Ahuja <aahuja11@gmail.com>,                              *)
(*          Jeff Hammerbacher <jeff.hammerbacher@gmail.com>               *)
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

open Internal_pervasives

type t ={
  kind : [ `Directory | `File ];
  path : string;
} [@@deriving yojson]

let canonicalize p =
  String.split ~on:(`Character '/') p
  |> begin function
  | [] | [""] | [""; ""] -> [""; ""]
  | "" :: more -> "" :: List.filter more ~f:((<>) "")
  | other -> List.filter other ~f:((<>) "")
  end
  |> String.concat ~sep:"/"

let file path :  t =
  {kind = `File; path = canonicalize path}

let directory path :  t  =
  {kind = `Directory; path = canonicalize path}

let root : t = directory "/"

let raise_invalid_arg path msg =
  invalid_argument_exn ~where:"Path"
    (fmt "%s %s" path msg)

let absolute_file_exn s : t =
  if Filename.is_relative s
  then raise_invalid_arg s "is not an absolute file path"
  else file s
let absolute_directory_exn s : t =
  if Filename.is_relative s
  then raise_invalid_arg s "is not an absolute directory path"
  else directory s
let relative_directory_exn s : t =
  if Filename.is_relative s
  then directory s
  else raise_invalid_arg s "is not a relative directory path"
let relative_file_exn s : t =
  if Filename.is_relative s
  then file s
  else raise_invalid_arg s "is not a relative file path"

let concat = fun x y -> { kind = y.kind; path = Filename.concat x.path y.path}

let to_string: t -> string = fun x -> x.path
let to_string_quoted: t -> string = fun x -> Filename.quote x.path

let size_shell_command = function
| {kind = `File; path } ->
  fmt "\\ls -nl %s | awk '{print $5}'" (Filename.quote path)
| {kind = `Directory; path } ->  "echo '0'"

let exists_shell_condition = function
| {kind = `File; path } ->  fmt "[ -f %s ]" (Filename.quote path)
| {kind = `Directory; path } ->  fmt "[ -d %s ]" (Filename.quote path)

let markup p =
  Display_markup.path (to_string p)
