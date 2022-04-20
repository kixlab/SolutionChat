defmodule DB.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    belongs_to(:room, DB.Room)
    belongs_to(:user, User)
    belongs_to(:entity, Entity)
    field(:kind, :string)
    field(:name, :string)
    field(:text, :string)
    field(:localID, :string)
    field(:vote_position, :string)
    field(:poll_id, :integer)
    field(:command, :string)
    field(:parent, :integer)
    timestamps()
  end

  @fields ~w(kind name text room_id user_id vote_position poll_id command parent)

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> cast_assoc(:room)
    |> put_assoc(:entity, params[:entity])
    |> validate_required([:name, :text, :kind])
  end
end
