defmodule MicrongoPhx.Repo.Migrations.AlterSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :code, :string
    end
  end
end
