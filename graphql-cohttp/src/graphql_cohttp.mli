module type HttpBody = sig
  type t
  type +'a io

  val to_string : t -> string io
  val of_string : string -> t
end

module Make
  (Schema : Graphql_intf.Schema)
  (Io : Cohttp.S.IO with type 'a t = 'a Schema.Io.t)
  (Body : HttpBody with type +'a io := 'a Schema.Io.t) : sig

  type response_action =
    (* The connection is not closed in the [`Expert] case until the [unit
       Async_kernel.Deferred.t] becomes determined. *)
    [ `Expert of Cohttp.Response.t
                 * (Io.ic
                    -> Io.oc
                    -> unit Io.t)
    | `Response of Cohttp.Response.t * Body.t ]

  type 'conn callback =
    'conn ->
    Cohttp.Request.t ->
    Body.t ->
    response_action Schema.Io.t

  val execute_request :
    'ctx Schema.schema ->
    'ctx ->
    Cohttp.Request.t ->
    Body.t ->
    response_action Schema.Io.t

  val make_callback :
    (Cohttp.Request.t -> 'ctx) ->
    'ctx Schema.schema ->
    'conn callback
end
