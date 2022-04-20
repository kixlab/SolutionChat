defmodule Message.Logic do
  alias MicrongoPhx.Repo

  def after_load(%DB.Message{} = message) do
    Repo.preload(message, [:user])
  end
end
