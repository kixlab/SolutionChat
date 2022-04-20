defmodule MicrongoPhxWeb.NGOController do
  use MicrongoPhxWeb, :controller
  alias MicrongoPhx.Repo

  def index(conn, %{"id" => id}) do
    {id, _} = Integer.parse(id)

    uid = get_session(conn, :uid)
    IO.inspect(conn)

    token =
      if uid == nil do
        ""
      else
        Phoenix.Token.sign(conn, "user socket", uid)
      end

    case Repo.get(DB.Room, id) do
      nil -> render(conn, "not_found.html")
      room -> render(conn, "index.html", room: room, token: token)
    end
  end
end
