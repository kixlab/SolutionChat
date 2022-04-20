defmodule Room.Query do
  import Ecto.Query
  alias MicrongoPhx.Repo

  def query() do
    from(r in DB.Room, select: r, preload: [])
  end

  def where_id(query, id) do
    from(r in query, where: r.id == ^id)
  end

  ## ACTIONS

  def find_by_id(id) do
    query()
    |> where_id(id)
    |> Repo.one()
  end

  def update_by_room_state(room_state) do
    old = find_by_id(room_state.id)

    DB.Room.changeset(old, %{
      room_level: room_state.room_level,
      started: room_state.started,
      topics: room_state.topics
    })
    |> Repo.update()
  end
end
