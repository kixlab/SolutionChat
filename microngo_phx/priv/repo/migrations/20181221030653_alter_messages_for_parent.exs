defmodule MicrongoPhx.Repo.Migrations.AlterMessagesForParent do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :parent, :integer
    end
  end
end
