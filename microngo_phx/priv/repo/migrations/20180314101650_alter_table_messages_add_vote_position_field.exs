defmodule MicrongoPhx.Repo.Migrations.AlterTableMessagesAddVotePositionField do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :vote_position, :string
    end
  end
end
