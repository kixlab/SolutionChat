defmodule MicrongoPhxWeb.ExpController do
  use MicrongoPhxWeb, :controller
  alias MicrongoPhx.Repo

  import Ecto.Query

  plug :put_layout, "blank.html"

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def create(conn, params) do
    {:ok, start} = Timex.parse params["start"], "{YYYY}-{0M}-{0D} {h24}:{m}"
    start = Timex.to_datetime(start, "Asia/Seoul")

    changeset =
      DB.Room.changeset(%DB.Room{}, %{
        title: params["title"],
        room_level: 0,
        condition: params["condition"],
        start_at: start,
        started: false,
        redeem_code_waiting: random_string(6),
        redeem_code_done: random_string(6)
      })
    {:ok, room} = MicrongoPhx.Repo.insert(changeset)
    Room.Supervisor.start_room(room.id)
    render(conn, "create.html", roomID: room.id)
  end

  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end
end
