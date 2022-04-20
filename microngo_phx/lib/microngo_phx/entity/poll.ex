defmodule Poll do
  use Ecto.Schema
  import Ecto.Changeset

  schema "polls" do
    belongs_to(:room, DB.Room)
    field(:title, :string)
    field(:begin_at, :utc_datetime)
    field(:end_at, :utc_datetime)
    field(:entity_type, :string)
    belongs_to(:entity_parent, Entity, foreign_key: :entity_parent_id)
    timestamps()
  end

  @fields ~w(room_id title begin_at end_at entity_type entity_parent_id)

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
  end
end
