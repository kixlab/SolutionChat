defmodule MicrongoPhx.Repo.Migrations.CreateChatRoom do
  use Ecto.Migration
  def change do
    create table(:room) do
      add :title, :string
      timestamps()
    end
  end
end
