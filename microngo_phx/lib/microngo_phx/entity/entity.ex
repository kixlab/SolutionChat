defmodule Entity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "entities" do
    field(:type, :string)
    field(:title, :string)
    field(:reference_type, :string)
    field(:reference, :string)
    belongs_to(:parent, Entity, foreign_key: :parent_id)
    has_many(:childrens, Entity, foreign_key: :parent_id)
    belongs_to(:room, DB.Room, foreign_key: :room_id)
    timestamps()
  end

  @fields ~w(type title reference_type reference parent_id room_id)

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
  end
end
