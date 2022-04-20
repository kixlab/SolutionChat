defmodule Entity.Query do
  alias MicrongoPhx.Repo
  import Ecto.Query
  # field :type, :string
  #   field :title, :string
  #   field :reference_type, :string
  #   field :reference, :string
  #   belongs_to :parent, Entity, foreign_key: :parent_id
  def new(room_id, type, title, reference, parent_entity_id) do
    params = %{
      room_id: room_id,
      type: type,
      title: title,
      reference: reference,
      parent_id: parent_entity_id
    }

    Entity.changeset(%Entity{}, params)
    |> Repo.insert()
  end

  def all() do
    from(e in Entity, select: e, preload: [])
  end

  def get_by_id(entity_id) do
    all = all()
    query = from(e in all, where: e.id == ^entity_id)
    Repo.one(query)
  end

  def all_by_room_id(room_id) do
    all = all()
    query = from(e in all, where: e.room_id == ^room_id)
    Repo.all(query)
  end
end
