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

type relative 
type absolute
type file
type directory
type 'c t =
  (* {kind: [`File | `Directory]; path: string} *)
  Ketrew_gen_base_v0_t.path
  constraint 'c = <relativity: 'relativity; kind: 'file_kind>
open Ketrew_gen_base_v0_t
type absolute_directory = <relativity : absolute; kind: directory> t
type absolute_file = <relativity : absolute; kind: file> t
type relative_directory = <relativity : relative; kind: directory> t
type relative_file = <relativity : relative; kind: file> t

let file path : <relativity : 'a; kind: file>  t =
  {kind = `File; path}

let directory path : <relativity : 'a; kind: directory> t  =
  {kind = `Directory; path}

let root : <relativity : absolute; kind: directory> t = directory "/"

let absolute_file_exn s : <relativity : absolute; kind: file> t =
  if Filename.is_relative s
  then invalid_argument_exn ~where:"Path" "absolute_file_exn"
  else file s
let absolute_directory_exn s : <relativity : absolute; kind: directory> t =
  if Filename.is_relative s
  then invalid_argument_exn ~where:"Path" "absolute_directory_exn"
  else directory s
let relative_directory_exn s : <relativity : relative; kind: directory> t =
  if Filename.is_relative s
  then directory s
  else invalid_argument_exn ~where:"Path" "relative_directory_exn"
let relative_file_exn s : <relativity: relative; kind: file> t =
  if Filename.is_relative s
  then file s
  else invalid_argument_exn ~where:"Path" "relative_file_exn"

let concat: <relativity: 'a; kind: directory> t ->
  <relativity: relative; kind: 'b> t -> <relativity: 'a; kind: 'b> t =
  fun x y ->
    { kind = y.kind; path = Filename.concat x.path y.path}

let to_string: 'a t -> string = fun x -> x.path
let to_string_quoted: 'a t -> string = fun x -> Filename.quote x.path

let any_kind: <relativity: 'a; kind: 'b> t -> <relativity: 'a; kind: 'c> t =
  fun x -> { x with kind = x.kind }

let exists_shell_condition = function
| {kind = `File; path } ->  fmt "[ -f %S ]" path
| {kind = `Directory; path } ->  fmt "[ -d %S ]" path

