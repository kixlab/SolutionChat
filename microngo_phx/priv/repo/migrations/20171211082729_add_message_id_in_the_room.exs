defmodule MicrongoPhx.Repo.Migrations.AddMessageIdInTheRoom do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :localID, :string
    end
  end
end
