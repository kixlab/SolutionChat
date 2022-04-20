defmodule Prompt.UserIdleServer do
  alias Prompt.UserIdleServer
  defstruct room_id: nil, users: %{}, timer: nil, interval: 60000, combo: 0
  use GenServer

  def start_link(opt) do
    GenServer.start_link(__MODULE__, opt)
  end

  def user_say(pid, user_name) do
    GenServer.cast(pid, {:user_say, user_name})
  end

  def init(opts) do
    {:ok, %UserIdleServer{
      room_id: Keyword.get(opts, :room_id),
      timer: Process.send_after(self(), :prompt_time, Keyword.get(opts, :interval)),
      interval: Keyword.get(opts, :interval)
    }}
  end

  def handle_cast({:user_say, user_name}, state) do
    new_state = %UserIdleServer{state|
      users: Map.put(state.users, user_name, System.system_time(:second))
    }

    IO.inspect new_state
    {:noreply, new_state}
  end

  def handle_info(:prompt_time, state) do
    IO.puts "this is time"
    IO.inspect state
    room_state = Room.Server.get_state(state.room_id)
    moderator_user = Enum.find(room_state.users, fn {_, v} ->
      v.id == room_state.moderator_id
    end)
    moderator_user = case moderator_user do
      nil -> nil
      {_, v} -> v
    end
    IO.inspect moderator_user
    new_users = if moderator_user == nil do
      state.users
    else
      Map.delete(state.users, moderator_user.username)
    end
    finding_maxima = Enum.reduce(new_users, nil, fn {k, v}, acc ->
      IO.inspect {k, v}
      IO.inspect acc
      case acc do
        nil -> {k, v}
        {min_k, min_v} ->
          if v < min_v do
            {k,v}
          else
            {min_k, min_v}
          end
      end
    end)
    IO.inspect finding_maxima
    case finding_maxima do
      nil ->
        {:noreply, state}
      {max_username, _} ->
        Room.Server.add_advice(state.room_id, %Advice{
          kind: "prompt_new_idea_user", title: "활동안하는 참가자의 의견도 유도해보세요", body: "다양한 의견은 토론 품질을 높혀줍니다", message: "#{max_username}님의 의견이 궁금해요 말씀해주시겠어요?"
        })
    end

    {:noreply, %UserIdleServer{state|
      timer: Process.send_after(self(), :prompt_time, state.interval),
    }}
  end
end
