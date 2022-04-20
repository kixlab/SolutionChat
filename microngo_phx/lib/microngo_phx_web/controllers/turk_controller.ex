defmodule MicrongoPhxWeb.TurkController do
  use MicrongoPhxWeb, :controller
  alias MicrongoPhx.Repo

  import Ecto.Query

  def index(conn, _params) do
    now = Timex.now() |> Timex.shift(seconds: 60)
    query = from(room in DB.Room, where: room.id > 999 and room.start_at >= ^now)
    rooms = Repo.all(query)

    room_id =
      Enum.reduce(rooms, nil, fn room, acc ->
        if acc == nil do
          Room.Supervisor.start_room(room.id)
          if Room.Server.is_new_member_allowed(room.id) == true do
            room.id
          else
            acc
          end
        else
          acc
        end
      end)

    room_id =
      if room_id == nil do
        changeset =
          DB.Room.changeset(%DB.Room{}, %{
            title: "공개SW 기여자 확보 문제",
            room_level: 0,
            condition: 3,
            start_at: Timex.shift(Timex.now(), minutes: 1),
            started: false,
            redeem_code_waiting: random_string(6),
            redeem_code_done: random_string(6)
          })

        {:ok, room} = MicrongoPhx.Repo.insert(changeset)
        Room.Supervisor.start_room(room.id)
        room.id
      else
        room_id
      end

    redirect(conn, to: "/room/index.html?room=#{room_id}")
  end

  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end
end
