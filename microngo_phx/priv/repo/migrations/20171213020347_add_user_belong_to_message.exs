defmodule MicrongoPhx.Repo.Migrations.AddUserBelongToMessage do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :user_id, references(:users)
    end
  end
end
