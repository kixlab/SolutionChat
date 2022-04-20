defmodule Message.Query do
  alias MicrongoPhx.Repo
  import Ecto.Query

  def previous_messages_from(room_id, from_id) do
    query = if from_id == nil do
      from(e in DB.Message,
        select: e,
        preload: [:user],
        where: e.room_id == ^room_id and e.kind != "log",
        order_by: [desc: e.id],
        limit: 20
      )
    else
      from(e in DB.Message,
        select: e,
        preload: [:user],
        where: e.room_id == ^room_id and e.id < ^from_id and e.kind != "log",
        order_by: [desc: e.id],
        limit: 20
      )
    end

    Repo.all(query)
    |> Enum.reverse()
  end
end
