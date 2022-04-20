defmodule MicrongoPhx.Repo.Migrations.AddRoomLevelToRoomTable do
  use Ecto.Migration

  def change do
    alter table(:room) do
      add :room_level, :integer
    end
  end
end
