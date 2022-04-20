defmodule MicrongoPhx.Repo.Migrations.AddingRoomIdToEntityTable do
  use Ecto.Migration

  def change do
    alter table(:entities) do
      add :room_id, references(:room)
    end
  end
end
