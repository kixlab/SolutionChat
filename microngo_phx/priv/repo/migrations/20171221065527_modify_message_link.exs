defmodule MicrongoPhx.Repo.Migrations.ModifyMessageLink do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :entity_id, references(:entities)
      remove :title
    end
  end
end
