defmodule MicrongoPhx.Repo.Migrations.AlterTableRoomForRedeemAndStart do
  use Ecto.Migration

  def change do
    alter table(:room) do
      add :started, :boolean
      add :redeem_code_waiting, :string
      add :redeem_code_done, :string
    end
  end
end
