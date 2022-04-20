defmodule MicrongoPhx.Repo.Migrations.AddingMessageLinkTable do
  use Ecto.Migration

  def change do
    create table(:message_links) do
      add :message_id, references(:messages)
      add :problem_id, references(:problems)
    end
  end
end
