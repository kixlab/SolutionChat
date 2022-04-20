defmodule Problem.Server do
  defstruct id: nil, room: nil, title: ""
  use GenServer

  ## opt = [problem_id, {title: title}]
  def start_link([problem_id | _] = opt) do
    name = via_tuple(problem_id)
    GenServer.start_link(__MODULE__, opt, name: name)
  end

  defp via_tuple(problem_id) do
    {:via, Registry, {:problem_registry, problem_id}}
  end

  def set_title(pid, title) do
    GenServer.cast(pid, {:update, title})
  end

  def broadcast(pid) do
    GenServer.cast(pid, {:broadcast})
  end

  def get_state(pid), do: GenServer.call(via_tuple(pid), {:get_state})

  #######################################
  ## 문제 R1P1
  ## 원인 R1P1F1
  ## 증거 R1P1F1E1
  ## 해결책 R1P1S1
  ## 해결책장점 R1P1S1G1
  ## 해결책단점 R1P1S1B1
  ## 추진방법 R1P1S1T1

  # problem_ID 파싱 (C1P1)

  def init([problem_id | rest]) when is_bitstring(problem_id) do
    init(rest, %Problem{
      id: problem_id,
      room: get_roomid_from_identifier(problem_id)
    })
  end

  def init([{:title, title} | rest], state) do
    init(rest, %{state | title: title})
  end

  def init([], state) do
    ## initial broadcasting
    Problem.Server.broadcast(self())
    {:ok, state}
  end

  defp get_roomid_from_identifier(identifier) do
    regex = ~r/R(\d+)/
    [_, result] = Regex.run(regex, identifier)
    Integer.parse(result) |> elem(0)
  end

  def handle_cast({:update, title}, state) do
    state = Map.put(state, :title, title)
    Problem.Server.broadcast(self())
    {:noreply, state}
  end

  def handle_cast({:broadcast}, state) do
    IO.puts("Broadcasting " <> state.id)

    Room.Server.broadcast_upstream(state.room, %ChangeEvent{event_name: "problem", payload: state})

    {:noreply, state}
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end
end
