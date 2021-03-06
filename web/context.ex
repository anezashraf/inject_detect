defmodule InjectDetect.Web.Context do
  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    case build_context(conn) do
      {:ok, context} ->
        put_private(conn, :absinthe, %{context: context})
      {:error, reason} ->
        conn
        |> send_resp(403, "Unauthorized")
        |> halt()
      _ ->
        conn
        |> send_resp(400, "Bad Request")
        |> halt()
    end
  end

  def build_context(conn) do
    with ["Bearer " <> auth_token] <- get_req_header(conn, "authorization"),
         {:ok, user_id}            <- authorize(auth_token)
    do
      {:ok, %{user_id: user_id}}
    else
      []    -> {:ok, %{}}
      error -> error
    end
  end

  defp authorize(auth_token) do
    InjectDetect.State.User.find(auth_token: auth_token)
    |> with_user
  end

  defp with_user(nil), do: {:error, "Invalid authorization token"}
  defp with_user(user), do: InjectDetect.verify_token(user.auth_token)

end
