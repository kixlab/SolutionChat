defmodule MicrongoPhx.Repo.Migrations.AlterTableMessagesToAddCurrentPoll do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :poll_id, :integer
    end
  end
end
