defmodule MicrongoPhx.Repo.Migrations.AddingProblemTable do
  use Ecto.Migration

  def change do
    create table(:problems) do
      add :title, :string
      add :room_id, references(:room)
      add :message_id, references(:messages)
      timestamps()
    end
  end
end
