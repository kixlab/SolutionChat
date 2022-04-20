defmodule Prompt.TimeManagementServer do
  alias Prompt.TimeManagementServer
  defstruct room_id: nil, timer: nil, interval: 180000, combo: 0
  use GenServer

  def start_link(opt) do
    GenServer.start_link(__MODULE__, opt)
  end

  def postpond(pid) do
    GenServer.cast(pid, :postpond)
  end

  def init(opts) do
    {:ok, %TimeManagementServer{
      room_id: Keyword.get(opts, :room_id),
      timer: Process.send_after(self(), :prompt_time, Keyword.get(opts, :interval)),
      interval: Keyword.get(opts, :interval)
    }}
  end

  def handle_cast(:postpond, state) do
    Process.cancel_timer(state.timer)
    new_state = %TimeManagementServer{state|
      timer: Process.send_after(self(), :prompt_time, state.interval),
      combo: 0
    }
    {:noreply, new_state}
  end

  def handle_info(:prompt_time, state) do
    IO.inspect "time_management"
    room_state = Room.Server.get_state(state.room_id)
    finish_at = Timex.shift(room_state.start_at, minutes: room_state.duration)
    remaining = Timex.diff(finish_at, Timex.now(), :minutes)
    if room_state.topics["orders"] == nil do
      {:noreply, state}
      IO.inspect "time_management nil"
    else
      IO.inspect "time_management do"
      remained_topics = Enum.reduce(room_state.topics["orders"], 0, fn x, acc ->
        topic = Discussion.Topics.get_topic(room_state.topics, x)
        if topic["completed"] == false do
          acc + 1
        else
          acc
        end
      end)
      per_topic_minutes = if remained_topics > 0 do
        Float.floor(remaining / remained_topics)
      else
        0
      end
      per_topic_minutes = trunc(per_topic_minutes)

      if remaining > 0 do
        Room.Server.add_advice(state.room_id, %Advice{
          kind: "prompt_time_1", title: "남은 토의시간을 상기하세요", body: "토의에 있어 시간 관리는 중요합니다", message: "전체 토의시간이 #{remaining}분 남았습니다"
        })
      end
      if per_topic_minutes < 0 do
        Room.Server.add_advice(state.room_id, %Advice{
          kind: "prompt_time_2", title: "남은 토의시간을 상기하세요", body: "토의에 있어 시간 관리는 중요합니다", message: "시간이 없어서 아주 조금만 더 이야기할 수 있습니다"
        })
      else
        Room.Server.add_advice(state.room_id, %Advice{
          kind: "prompt_time_3", title: "남은 토의시간을 상기하세요", body: "토의에 있어 시간 관리는 중요합니다", message: "#{per_topic_minutes}분만 더 쓸 수 있을것 같습니다."
        })
      end

      new_state = %TimeManagementServer{state|
        timer: Process.send_after(self(), :prompt_time, state.interval),
        combo: 0
      }
      {:noreply, new_state}
    end
  end
end
