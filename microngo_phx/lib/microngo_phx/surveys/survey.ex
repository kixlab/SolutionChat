defmodule MicrongoPhx.Surveys.Survey do
  use Ecto.Schema
  import Ecto.Changeset

  schema "surveys" do
    field :room_id, :integer
    field :name, :string
    field :json, :string
    field :code, :string
    timestamps()
  end

  @fields ~w(room_id name json code)

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> validate_required([:room_id, :name])
  end

end
