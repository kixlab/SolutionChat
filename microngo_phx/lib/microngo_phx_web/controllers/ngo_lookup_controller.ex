defmodule MicrongoPhxWeb.NGOLookupController do
  use MicrongoPhxWeb, :controller

  alias MicrongoPhx.Repo

  def index(conn, _params) do
    rooms =
      Rooms.whole()
      |> Rooms.order_by_id()
      |> Repo.all()

    render(conn, "index.html", rooms: rooms)
  end
end
