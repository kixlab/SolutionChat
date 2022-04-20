defmodule DB.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "room" do
    field(:title, :string)
    field(:room_level, :integer)
    field(:condition, :integer)
    field(:start_at, :utc_datetime)
    field :started, :boolean
    field :redeem_code_waiting, :string
    field :redeem_code_done, :string
    field :topics, :map
    timestamps()
  end

  @fields ~w(title room_level condition start_at started redeem_code_waiting redeem_code_done topics)

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> validate_required([:title])
  end
end
