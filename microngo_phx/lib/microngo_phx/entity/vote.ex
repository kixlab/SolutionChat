defmodule Vote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "votes" do
    belongs_to(:poll, Poll)
    belongs_to(:entity, Entity)
    belongs_to(:user, User)
    field(:value, :integer)
    timestamps()
  end

  @fields ~w(poll_id user_id entity_id value)

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> validate_required([:value])
  end
end
