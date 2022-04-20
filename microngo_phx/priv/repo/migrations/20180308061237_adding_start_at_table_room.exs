defmodule MicrongoPhx.Repo.Migrations.AddingStartAtTableRoom do
  use Ecto.Migration

  def change do
    alter table(:room) do
      add :start_at, :utc_datetime
    end  
  end
end
