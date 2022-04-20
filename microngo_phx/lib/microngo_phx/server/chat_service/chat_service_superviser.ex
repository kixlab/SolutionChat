defmodule ChatService.Supervisor do
  import Supervisor.Spec

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(ChatService.StashServer, [], restart: :permanent),
      supervisor(Room.Supervisor, [], restart: :permanent)
    ]
    supervise(children, strategy: :one_for_one)
  end
end
