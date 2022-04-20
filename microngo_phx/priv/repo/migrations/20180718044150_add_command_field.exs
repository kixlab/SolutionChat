defmodule MicrongoPhx.Repo.Migrations.AddCommandField do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :command, :string
    end
  end
end
