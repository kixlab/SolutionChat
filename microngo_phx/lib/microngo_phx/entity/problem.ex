defmodule Problem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "problems" do
    belongs_to(:room, DB.Room)
    belongs_to(:message, DB.Message)
    field(:local_id, :string)
    field(:title, :string)
    timestamps()
  end

  @fields ~w(title room_id local_id message_id)

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> cast_assoc(:room)
    |> cast_assoc(:message)
    |> validate_required([:title])
  end
end
