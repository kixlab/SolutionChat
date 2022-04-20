defmodule MicrongoPhx.Repo.Migrations.AddingTopicsToRoom do
  use Ecto.Migration

  def change do
    alter table(:room) do
      add :topics, :map
    end
  end
end
