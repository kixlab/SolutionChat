defmodule MicrongoPhx.Repo.Migrations.AddLocalIdToProblemTable do
  use Ecto.Migration

  def change do
    alter table(:problems) do
      add :local_id, :string
    end
  end
end
