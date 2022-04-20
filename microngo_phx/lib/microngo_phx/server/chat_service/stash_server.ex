defmodule ChatService.StashServer do
  alias ChatService.StashServer
  use GenServer
  defstruct states: %{}

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: :stash_server)
  end

  def stash(room_id, room_state) do
    GenServer.cast(:stash_server,  {:stash, room_id, room_state})
  end

  def fetch(room_id) do
    GenServer.call(:stash_server,  {:fetch, room_id})
  end

  ###

  def init(:ok) do
    {:ok, %StashServer{}}
  end

  def handle_cast({:stash, room_id, room_state}, state) do
    new_state = %StashServer{state|
      states: Map.put(state.states, room_id, room_state)
    }
    {:noreply, new_state}
  end

  def handle_call({:fetch, room_id}, _from, state) do
    recall = Map.get(state.states, room_id, nil)
    {:reply, recall, state}
  end

end
