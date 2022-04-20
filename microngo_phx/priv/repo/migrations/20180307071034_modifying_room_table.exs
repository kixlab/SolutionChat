defmodule MicrongoPhx.Repo.Migrations.ModifyingRoomTable do
  use Ecto.Migration

  def change do
    alter table(:room) do
      add :condition, :integer
    end  
  end
end