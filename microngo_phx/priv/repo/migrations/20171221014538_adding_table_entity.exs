defmodule MicrongoPhx.Repo.Migrations.AddingTableEntity do
  use Ecto.Migration

  def change do
    create table(:entities) do
      add :type, :string
      add :title, :string
      add :reference_type, :string
      add :reference, :string
      add :parent_id, references(:entities)
      timestamps()
    end
  end
end
