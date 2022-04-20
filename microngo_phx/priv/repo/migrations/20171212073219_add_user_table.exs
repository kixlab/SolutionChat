defmodule MicrongoPhx.Repo.Migrations.AddUserTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:email, :string)
      add(:password, :string)
      add(:username, :string)
      timestamps()
    end
  end
end
