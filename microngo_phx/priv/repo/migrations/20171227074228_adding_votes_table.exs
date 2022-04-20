defmodule MicrongoPhx.Repo.Migrations.AddingVotesTable do
  use Ecto.Migration

  def change do
    create table(:votes) do      
      add :poll_id, references(:polls)
      add :entity_id, references(:entities)
      add :user_id, references(:users)
      add :value, :integer
      timestamps()
    end
  end
end
