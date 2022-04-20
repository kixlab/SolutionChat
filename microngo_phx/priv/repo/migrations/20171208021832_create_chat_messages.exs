defmodule MicrongoPhx.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :room_id, references(:room)
      add :kind, :string
      add :name, :string
      add :text, :string
      add :title, :string
      timestamps()
    end
  end
end
