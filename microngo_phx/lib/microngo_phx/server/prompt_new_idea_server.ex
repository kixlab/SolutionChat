defmodule Prompt.NewIdeaServer do
  alias Prompt.NewIdeaServer
  defstruct room_id: nil, timer: nil, interval: 60000, combo: 0
  use GenServer

  def start_link(opt) do
    GenServer.start_link(__MODULE__, opt)
  end

  def postpond(pid) do
    GenServer.cast(pid, :postpond)
  end

  def init(opts) do
    {:ok, %NewIdeaServer{
      room_id: Keyword.get(opts, :room_id),
      timer: Process.send_after(self(), :prompt_time, Keyword.get(opts, :interval)),
      interval: Keyword.get(opts, :interval)
    }}
  end

  def handle_cast(:postpond, state) do
    Process.cancel_timer(state.timer)
    new_state = %NewIdeaServer{state|
      timer: Process.send_after(self(), :prompt_time, state.interval),
      combo: 0
    }
    {:noreply, new_state}
  end

  def handle_info(:prompt_time, state) do
    if state.combo <= 2 do
      new_state = %NewIdeaServer{state|
        timer: Process.send_after(self(), :prompt_time, state.interval),
        combo: (state.combo + 1)
      }
      Room.Server.add_advice(state.room_id, %Advice{
        kind: "prompt_new_idea", title: "다른 아이디어를 독려하세요", body: "다양한 의견은 토론 품질을 높혀줍니다", message: "다른 의견은 없으신가요?"
      })
      {:noreply, new_state}
    else
      new_state = %NewIdeaServer{state|
        timer: Process.send_after(self(), :prompt_time, state.interval),
        combo: 0
      }
      Room.Server.add_advice(state.room_id, %Advice{
        kind: "prompt_reduce_scope", title: "토론 범위를 줄여보세요", body: "너무 오랫동안 의견개진이 되지 않았습니다", message: "토론범위를 줄여서 토론해볼까요?"
      })
      Room.Server.add_advice(state.room_id, %Advice{
        kind: "prompt_vote", title: "투표를 독려하세요", body: "의견이 확정되어야 토론 효율이 좋아집니다", message: "이제까지 나온 의견들에 대해 투표할까요?"
      })
      Room.Server.add_advice(state.room_id, %Advice{
        kind: "prompt_next", title: "다음 의견 진행을 독려하세요", body: "다음 순서로 갈까요?", message: "이제 다음 순서로 갈까요?"
      })
      {:noreply, new_state}
    end
  end
end
