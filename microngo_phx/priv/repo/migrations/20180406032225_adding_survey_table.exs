defmodule MicrongoPhx.Repo.Migrations.AddingSurveyTable do
  use Ecto.Migration

  def change do
    create table(:surveys) do
      add :room_id, :integer
      add :name, :string
      add :json, :text
      timestamps()
    end
  end
end
