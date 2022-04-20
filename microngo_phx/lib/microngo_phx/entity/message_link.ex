defmodule MessageLink do
  use Ecto.Schema
  import Ecto.Changeset

  schema "message_links" do
    belongs_to(:message, DB.Message)
    belongs_to(:problem, Problem)
  end

  @fields ~w(message_id problem_id)


  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> put_assoc(:problem, params.problem)
  end
end
