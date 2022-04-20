defmodule Poll.Query do
  import Ecto.Query
  alias MicrongoPhx.Repo

  def all() do
    from(p in Poll, select: p, preload: [])
  end

  # where
  def where_room_id(query, room_id) do
    from(p in all(), where: p.room_id == ^room_id)
  end

  def all_for_room_id(room_id) do
    query =
      all()
      |> where_room_id(room_id)

    Repo.all(query)
  end

  def extend_poll_end_at(poll) do
    Poll.changeset(poll, %{
      end_at: Timex.now() |> Timex.shift(hours: 24)
    })
    |> MicrongoPhx.Repo.update()
  end
end
