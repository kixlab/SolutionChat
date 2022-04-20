defmodule Room.Supervisor do
  import Supervisor.Spec

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_room(roomID) do
    Supervisor.start_child(__MODULE__, [roomID])
  end

  def init(:ok) do
    children = [
      worker(Room.Server, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
