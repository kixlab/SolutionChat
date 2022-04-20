defmodule MicrongoPhx.Repo.Migrations.AddingVoteTable do
  use Ecto.Migration

  def change do
    create table(:polls) do
      add :room_id, references(:room)
      add :title, :string
      add :begin_at, :utc_datetime
      add :end_at, :utc_datetime
      add :entity_type, :string
      add :entity_parent_id, references(:entities)
      timestamps()
    end
  end
end
