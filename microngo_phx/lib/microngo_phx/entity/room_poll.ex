defmodule Room.Poll do
  import Ecto.Query
  alias MicrongoPhx.Repo

  def load_polls_from_db(%Room.Server{id: id} = room_state) do
    polls =
      Repo.all(from(p in Poll, where: p.room_id == ^id))
      |> Helper.Query.db_list_to_map()

    %{room_state | polls: polls}
  end

  def load_state_of_last_poll_from_db(%{id: id, polls: polls} = state) do
    # Find a poll with the maxima ID

    # top_poll =
    #   Enum.reduce(polls, nil, fn
    #     {_, poll}, nil -> poll
    #     {key, poll}, %{id: accid} when accid < key -> poll
    #     _, acc -> acc
    #   end)

    ordered_polls =
      polls
      |> Enum.reduce([], fn ({_, v}, acc) -> acc ++ [v] end)
      |> Enum.sort(fn(a, b) -> a.id >= b.id  end) #High to Low

    IO.puts "Loading poll"
    IO.inspect Enum.count(ordered_polls)
    IO.inspect ordered_polls

    cond do
      Enum.count(ordered_polls) == 0 ->
        %{state|
          poll: nil
        }
      Enum.count(ordered_polls) == 1 ->
        %{state|
          poll: Enum.at(ordered_polls, 0),
          previous_poll: Enum.at(ordered_polls, 1)
        }
      Enum.count(ordered_polls) >= 2 ->
        %{state|
          poll: Enum.at(ordered_polls, 0),
          previous_poll: Enum.at(ordered_polls, 1)
        }
    end
  end

  def process_poll(%{poll: poll} = room_state) do
    consensus = consensus_from_poll(room_state)
    consensus? = poll_next_trigger?(room_state)

    cond do
      room_state.condition != 1 ->
        room_state
      room_state.started == false ->
        # it is not started at all
        room_state

      room_state.room_level == 0 ->
        # 토론이 시작되지 않았으니 아무것도 하지 않는다
        room_state

      room_state.room_level == 100_000 ->
        # 모든 토론이 끝났으니 아무짓도 하지 않는다
        room_state

      poll == nil ->
        IO.puts("현재 폴 없어서 폴 진행")
        poll_new_by_room_state(room_state)

      is_poll_expired?(poll) ->
        IO.puts("폴 기한이 지났음")
        ranking = ranked_entity(room_state)

        case ranking do
          # extend the poll
          [] ->
            IO.puts("현재 폴의 대안 없어 연장")
            extend_current_poll(room_state)

          # 답변 확정  proceeed
          [first | _] ->
            # 답변 확정
            # 다음 폴
            IO.puts("다음 폴 띄움")

            entity = first.entity #%{entity_id: k, value: v, entity: Map.get(room_state.entities, k)}
            Room.Server.message_new(room_state.id, "consensus", "Bot", "#{room_state.poll.title}|||||#{entity.title}", poll_id: room_state.poll.id)

            if room_state.room_level >= 200 do
              NGOBot.change_stage(room_state.bot_pid, :new_problem)
            end

            room_state
            |> Room.Server.put_current_poll_to_previous_poll()
            |> poll_new_by_room_state()
        end

      consensus? ->
        IO.puts("동의가 이루어짐")
        {:consensus, %{entity: entity}} = consensus
        Room.Server.message_new(room_state.id, "consensus", "Bot", "#{room_state.poll.title}|||||#{entity.title}", poll_id: room_state.poll.id)

        if room_state.room_level >= 200 do
          NGOBot.change_stage(room_state.bot_pid, :new_problem)
        end

        # 답변 확정
        room_state
        |> Room.Server.put_current_poll_to_previous_poll()
        |> poll_new_by_room_state()

      true ->
        IO.puts("동의 없음")
        # 폴이 없는 것도 아니고
        # 끝나지도 않았고 그러면 여기 실행
        room_state
    end
  end

  def poll_next_trigger?(room_state) do
    population = Enum.count(room_state.users)
    target_vote_count = Float.ceil(population * 0.51)
    IO.puts("target_vote_count")
    IO.inspect(target_vote_count)

    consensus = consensus_from_poll(room_state)

    case consensus do
      {:consensus, one} ->
        IO.puts("CONSENSUS YES!")
        IO.inspect(one)
        IO.inspect(population)

        # one == %{entity_id: k, value: v, entity: Map.get(room_state.entities, k)}
        if one.value >= target_vote_count && one.value >= 2 do
          true
        else
          false
        end

      x ->
        IO.puts("no consensus")
        IO.inspect(x)
        false
    end
  end

  def extend_current_poll(room_state) do
    {:ok, poll} = Poll.Query.extend_poll_end_at(room_state.poll)
    %{room_state | poll: poll}
  end

  def ranked_entity(room_state) do
    # Reduce vote count
    Enum.reduce(room_state.votes, %{}, fn {_, v}, a ->
      entity_type =
        case Map.get(room_state.entities, v.entity_id, nil) do
          nil -> ""
          entity -> entity.type
        end

      if v.poll_id == room_state.poll.id do
        Map.get_and_update(a, v.entity_id, fn
          nil -> {nil, v.value}
          current_value -> {current_value, current_value + v.value}
        end)
        |> elem(1)
      else
        a
      end
    end)
    # reduce to list
    |> Enum.reduce([], fn {k, v}, acc ->
      acc ++ [%{entity_id: k, value: v, entity: Map.get(room_state.entities, k)}]
    end)
    # sorting higher to lower
    |> Enum.sort(fn x, y -> x.value > y.value end)
  end

  def consensus_from_poll(room_state) do
    entity_rank = ranked_entity(room_state)

    case entity_rank do
      [] ->
        {:no_consensus}

      [one] ->
        {:consensus, one}

      ranks ->
        first = Enum.at(ranks, 0)
        second = Enum.at(ranks, 1)
        is_tie? = first.value == second.value

        case is_tie? do
          true -> {:tie, first, second}
          false -> {:consensus, first}
        end
    end
  end

  defp gen_entity_rank_by_vote(list), do: gen_entity_rank_by_vote(list, %{})

  defp gen_entity_rank_by_vote([%{entity_id: entity_id, value: value} | t], map) do
    map =
      Map.get_and_update(map, entity_id, fn
        nil -> {nil, value}
        num -> {num, num + value}
      end)

    gen_entity_rank_by_vote(t, map)
  end

  defp gen_entity_rank_by_vote([], map) do
    Enum.map(map, fn {k, v} ->
      %{entity_id: k, value: v}
    end)
    |> Enum.sort(fn x, y -> x.value > y.value end)
  end

  def is_poll_expired?(poll) do
    poll.end_at < Timex.now()
  end

  defp poll_new(room_id, 100, parent_entity_id) do
    now = Timex.now()
    Poll.changeset(%Poll{}, %{
      room_id: room_id,
      title: "Did you read the problem?",
      begin_at: now,
      end_at: now |> Timex.shift(hours: 24),
      entity_type: "problem",
      entity_parent_id: parent_entity_id
    })
    |> MicrongoPhx.Repo.insert()
  end




  defp poll_new(room_id, 200, parent_entity_id) do
    now = Timex.now()

    Poll.changeset(%Poll{}, %{
      room_id: room_id,
      title: "이 문제의 원인은 무엇일까요?",
      begin_at: now,
      end_at: now |> Timex.shift(hours: 24),
      entity_type: "cause",
      entity_parent_id: parent_entity_id
    })
    |> MicrongoPhx.Repo.insert()
  end

  defp poll_new(room_id, 300, parent_entity_id) do
    now = Timex.now()

    Poll.changeset(%Poll{}, %{
      room_id: room_id,
      title: "이 원인의 증거는 무엇일까요?",
      begin_at: now,
      end_at: now |> Timex.shift(hours: 24),
      entity_type: "evidence",
      entity_parent_id: parent_entity_id
    })
    |> MicrongoPhx.Repo.insert()
  end

  defp poll_new(room_id, 400, parent_entity_id) do
    now = Timex.now()

    Poll.changeset(%Poll{}, %{
      room_id: room_id,
      title: "이 원인과 증거가 연관이 있고 유효한가요?",
      begin_at: now,
      end_at: now |> Timex.shift(hours: 24),
      entity_type: "route",
      entity_parent_id: parent_entity_id
    })
    |> MicrongoPhx.Repo.insert()
  end

  defp poll_new(room_id, 500, parent_entity_id) do
    now = Timex.now()

    Poll.changeset(%Poll{}, %{
      room_id: room_id,
      title: "이 원인을 풀기 위해 어떤 해결책을 제시할 수 있을까요?",
      begin_at: now,
      end_at: now |> Timex.shift(hours: 24),
      entity_type: "solution",
      entity_parent_id: parent_entity_id
    })
    |> MicrongoPhx.Repo.insert()
  end

  defp poll_new(room_id, 600, parent_entity_id) do
    now = Timex.now()

    Poll.changeset(%Poll{}, %{
      room_id: room_id,
      title: "이 해결책의 장점으로는 무엇이 있을까요?",
      begin_at: now,
      end_at: now |> Timex.shift(hours: 24),
      entity_type: "pro",
      entity_parent_id: parent_entity_id
    })
    |> MicrongoPhx.Repo.insert()
  end

  defp poll_new(room_id, 700, parent_entity_id) do
    now = Timex.now()

    Poll.changeset(%Poll{}, %{
      room_id: room_id,
      title: "이 해결책의 단점으로는 무엇이 있을까요?",
      begin_at: now,
      end_at: now |> Timex.shift(hours: 24),
      entity_type: "con",
      entity_parent_id: parent_entity_id
    })
    |> MicrongoPhx.Repo.insert()
  end

  defp poll_new(room_id, 800, parent_entity_id) do
    now = Timex.now()

    Poll.changeset(%Poll{}, %{
      room_id: room_id,
      title: "해결책의 장점과 단점을 고려했을때에도 좋은 해결책인가요?",
      begin_at: now,
      end_at: now |> Timex.shift(hours: 24),
      entity_type: "route",
      entity_parent_id: parent_entity_id
    })
    |> MicrongoPhx.Repo.insert()
  end

  defp poll_new(room_id, 900, parent_entity_id) do
    now = Timex.now()

    Poll.changeset(%Poll{}, %{
      room_id: room_id,
      title: "우리는 이 해결책을 위해 무슨행동을 하면 좋을까요?",
      begin_at: now,
      end_at: now |> Timex.shift(hours: 24),
      entity_type: "action_type",
      entity_parent_id: parent_entity_id
    })
    |> MicrongoPhx.Repo.insert()
  end

  # 청원 보내기
  defp poll_new(room_id, 10000, parent_entity_id) do
    now = Timex.now()

    Poll.changeset(%Poll{}, %{
      room_id: room_id,
      title: "청원을 누구에게 보내야 할까요?",
      begin_at: now,
      end_at: now |> Timex.shift(hours: 24),
      entity_type: "people_name",
      entity_parent_id: parent_entity_id
    })
    |> MicrongoPhx.Repo.insert()
  end

  defp poll_new(room_id, 11000, parent_entity_id) do
    now = Timex.now()

    Poll.changeset(%Poll{}, %{
      room_id: room_id,
      title: "청원받을 사람의 직함은 무엇인가요?",
      begin_at: now,
      end_at: now |> Timex.shift(hours: 24),
      entity_type: "people_title",
      entity_parent_id: parent_entity_id
    })
    |> MicrongoPhx.Repo.insert()
  end

  defp poll_new(room_id, 12000, parent_entity_id) do
    now = Timex.now()

    Poll.changeset(%Poll{}, %{
      room_id: room_id,
      title: "청원을 어떻게 전달할까요?",
      begin_at: now,
      end_at: now |> Timex.shift(hours: 24),
      entity_type: "people_contact",
      entity_parent_id: parent_entity_id
    })
    |> MicrongoPhx.Repo.insert()
  end

  # SNS 캠페인
  defp poll_new(room_id, 20000, parent_entity_id) do
    now = Timex.now()

    Poll.changeset(%Poll{}, %{
      room_id: room_id,
      title: "캐치프레이즈 (슬로건)은 무엇으로 하면 좋을까요?",
      begin_at: now,
      end_at: now |> Timex.shift(hours: 24),
      entity_type: "campaign_title",
      entity_parent_id: parent_entity_id
    })
    |> MicrongoPhx.Repo.insert()
  end

  defp poll_new(room_id, 21000, parent_entity_id) do
    now = Timex.now()

    Poll.changeset(%Poll{}, %{
      room_id: room_id,
      title: "온라인 어떤 곳에서 캠페인을 진행하면 좋을까요? (예: Twitter, 페이스북 등)",
      begin_at: now,
      end_at: now |> Timex.shift(hours: 24),
      entity_type: "campaign_channel",
      entity_parent_id: parent_entity_id
    })
    |> MicrongoPhx.Repo.insert()
  end

  # 토론 종결
  defp poll_new(room_id, 100_000, parent_entity_id) do
    now = Timex.now()

    Poll.changeset(%Poll{}, %{
      room_id: room_id,
      title: "토론이 끝났습니다",
      begin_at: now,
      end_at: now |> Timex.shift(hours: 24),
      entity_type: "debate_closed",
      entity_parent_id: parent_entity_id
    })
    |> MicrongoPhx.Repo.insert()
  end

  #Problem Ideation 인데 일단 삭제
  # defp poll_new_by_room_state(%{room_level: 0, id: id} = room_state) do
  #   db_result = poll_new(room_state.id, 100, nil)
  #   case db_result do
  #     {:ok, poll} ->
  #       Room.Server.save_room_state_to_db(room_state.id)

  #       room_state =
  #         room_state
  #         |> Map.put(:room_level, 100)
  #         |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
  #         |> Map.put(:poll, poll)

  #       spawn(fn ->
  #         Room.Server.message_new(
  #           room_state.id,
  #           "green",
  #           "Bot",
  #           "Good Job! We reached on consensus!"
  #         )

  #         :timer.sleep(3000)

  #         Room.Server.message_new(
  #           room_state.id,
  #           "green",
  #           "Bot",
  #           "Let's solve a real social problem"
  #         )

  #         :timer.sleep(3000)

  #         Room.Server.message_new(
  #           room_state.id,
  #           "green",
  #           "Bot",
  #           "Brainstorm about what is the problem with"
  #         )

  #         :timer.sleep(3000)
  #         Room.Server.message_new(room_state.id, "green", "Bot", room_state.room_title)
  #       end)

  #       Room.Server.message_new(room_state.id, "agenda", "Bot", poll.title)
  #       Room.Server.broadcast_state(room_state.id)

  #       %{room_state|
  #         in_tutorial: false
  #       }
  #     _ ->
  #       room_state
  #   end
  # end

  defp poll_new_by_room_state(%{room_level: 0, id: id} = room_state) do
    db_result = poll_new(room_state.id, 100, nil)

    case db_result do
      {:ok, poll} ->
        Room.Server.save_room_state_to_db(room_state.id)

        room_state =
          room_state
          |> Map.put(:room_level, 100)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)
          |> Map.put(:vote_only, true)
          |> Map.put(:vote_enabled, true)

        NGOBot.change_stage(room_state.bot_pid, :new_problem)
        Room.Server.broadcast_state(room_state.id)
        room_state

      _ ->
        room_state
    end
  end

  defp poll_new_by_room_state(%{room_level: 100, id: id} = room_state) do
    db_result = poll_new(room_state.id, 200, nil)

    case db_result do
      {:ok, poll} ->
        Room.Server.save_room_state_to_db(room_state.id)

        room_state =
          room_state
          |> Map.put(:room_level, 200)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)
          |> Map.put(:vote_only, false)
          |> Map.put(:vote_enabled, false)

        NGOBot.change_stage(room_state.bot_pid, :new_problem)
        Room.Server.broadcast_state(room_state.id)
        room_state

      _ ->
        room_state
    end
  end

  defp poll_new_by_room_state(%{room_level: 200, id: _} = room_state) do
    elected_entity =
      case consensus_from_poll(room_state) do
        {:consensus, one} ->
          one.entity

        {:tie, first, second} ->
          first.entity
          # {:no_consensus} -> WE can't expect this at this point
      end

    db_result = poll_new(room_state.id, 300, elected_entity.id)

    case db_result do
      {:ok, poll} ->
        Room.Server.save_room_state_to_db(room_state.id)

        room_state =
          room_state
          |> Map.put(:room_level, 300)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)

        Room.Server.broadcast_state(room_state.id)
        room_state

      _ ->
        room_state
    end
  end

  defp poll_new_by_room_state(%{room_level: 300, id: id} = room_state) do
    # 증거 선택 한후 토의 주제 고르기

    elected_entity =
      case consensus_from_poll(room_state) do
        {:consensus, one} ->
          one.entity

        {:tie, first, second} ->
          first.entity
          # {:no_consensus} -> WE can't expect this at this point
      end

    db_result = poll_new(room_state.id, 400, elected_entity.id)

    case db_result do
      {:ok, poll} ->
        Room.Server.save_room_state_to_db(room_state.id)

        room_state =
          room_state
          |> Map.put(:room_level, 400)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)
          |> Map.put(:vote_only, true)
          |> Map.put(:vote_enabled, true)
          # 증거 밑에 엔티티가 붙음
          |> insert_new_entity_to_room_state(
            "route",
            "네",
            "500",
            poll.entity_parent_id
          )
          |> insert_new_entity_to_room_state(
            "route",
            "아니오. 다시 원인을 토론합시다.",
            "200",
            poll.entity_parent_id
          )

        Room.Server.broadcast_state(room_state.id)
        room_state

      _ ->
        room_state
    end
  end

  defp poll_new_by_room_state(%{room_level: 400, id: id} = room_state) do
    # 토의 방향 고르기 후 디스패치
    IO.inspect room_state.poll

    elected_entity =
      case consensus_from_poll(room_state) do
        {:consensus, one} ->
          one.entity

        {:tie, first, second} ->
          first.entity
          # {:no_consensus} -> WE can't expect this at this point
      end

    case elected_entity.reference do
      "100" ->
        Room.Server.save_room_state_to_db(room_state.id)

        room_state
        |> Map.put(:room_level, 100)
        |> poll_new_by_room_state()

      "200" ->
        Room.Server.save_room_state_to_db(room_state.id)
        {:ok, poll} = poll_new(room_state.id, 200, nil)

        room_state =
          room_state
          |> Map.put(:room_level, 200)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)

        Room.Server.broadcast_state(room_state.id)
        room_state

      "500" ->
        parent_entity = one_entity_from_parent(room_state, "evidence", elected_entity)
        db_result = poll_new(room_state.id, 500, parent_entity.id)

        case db_result do
          {:ok, poll} ->
            Room.Server.save_room_state_to_db(room_state.id)

            room_state =
              room_state
              |> Map.put(:room_level, 500)
              |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
              |> Map.put(:poll, poll)
              |> Map.put(:vote_only, false)
              |> Map.put(:vote_enabled, false)

            Room.Server.broadcast_state(room_state.id)
            room_state

          _ ->
            room_state
        end
    end
  end

  defp poll_new_by_room_state(%{room_level: 500, id: id} = room_state) do
    # 해결책을 고른후 장점 이야기하기

    elected_entity =
      case consensus_from_poll(room_state) do
        {:consensus, one} ->
          one.entity

        {:tie, first, second} ->
          first.entity
          # {:no_consensus} -> WE can't expect this at this point
      end

    db_result = poll_new(room_state.id, 600, elected_entity.id)

    case db_result do
      {:ok, poll} ->
        Room.Server.save_room_state_to_db(room_state.id)

        room_state =
          room_state
          |> Map.put(:room_level, 600)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)
          |> Map.put(:vote_only, false)
          |> Map.put(:vote_enabled, false)

        Room.Server.broadcast_state(room_state.id)
        room_state

      _ ->
        room_state
    end
  end

  defp poll_new_by_room_state(%{room_level: 600, id: id} = room_state) do
    # 장점 고른후 단점 이야기하기

    elected_entity =
      case consensus_from_poll(room_state) do
        {:consensus, one} ->
          one.entity

        {:tie, first, second} ->
          first.entity
          # {:no_consensus} -> WE can't expect this at this point
      end

    db_result = poll_new(room_state.id, 700, elected_entity.id)

    case db_result do
      {:ok, poll} ->
        Room.Server.save_room_state_to_db(room_state.id)

        room_state =
          room_state
          |> Map.put(:room_level, 700)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)
          |> Map.put(:vote_only, false)
          |> Map.put(:vote_enabled, false)

        Room.Server.broadcast_state(room_state.id)
        room_state

      _ ->
        room_state
    end
  end

  defp poll_new_by_room_state(%{room_level: 700, id: id} = room_state) do
    # 단점을 고른후 토론 방향 정하기

    elected_entity =
      case consensus_from_poll(room_state) do
        {:consensus, one} ->
          one.entity

        {:tie, first, second} ->
          first.entity
          # {:no_consensus} -> WE can't expect this at this point
      end

    db_result = poll_new(room_state.id, 800, elected_entity.id)

    case db_result do
      {:ok, poll} ->
        Room.Server.save_room_state_to_db(room_state.id)

        room_state =
          room_state
          |> Map.put(:room_level, 800)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)
          |> insert_new_entity_to_room_state(
            "route",
            "네.",
            "900",
            poll.entity_parent_id
          )
          |> insert_new_entity_to_room_state(
            "route",
            "아니오. 다시 해결책을 토론합시다.",
            "500",
            poll.entity_parent_id
          )
          |> Map.put(:vote_only, true)
          |> Map.put(:vote_enabled, true)

        Room.Server.broadcast_state(room_state.id)

        room_state

      _ ->
        room_state
    end
  end

  defp poll_new_by_room_state(%{room_level: 800, id: id} = room_state) do
    # 토의 방향 고르기 후 디스패치

    elected_entity =
      case consensus_from_poll(room_state) do
        {:consensus, one} ->
          one.entity

        {:tie, first, second} ->
          first.entity
          # {:no_consensus} -> WE can't expect this at this point
      end

    case elected_entity.reference do
      "500" ->
        Room.Server.save_room_state_to_db(room_state.id)

        parent_entity = one_entity_from_parent(room_state, "evidence", elected_entity)
        {:ok, poll} = poll_new(room_state.id, 500, parent_entity.id)

        room_state =
          room_state
          |> Map.put(:room_level, 500)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)
          |> Map.put(:vote_only, false)
          |> Map.put(:vote_enabled, false)

        Room.Server.broadcast_state(room_state.id)
        room_state

      "900" ->
        Room.Server.save_room_state_to_db(room_state.id)

        # 단점 다음에 묶입니다
        parent_entity = one_entity_from_parent(room_state, "con", elected_entity)
        # 무슨일을 할까
        {:ok, poll} = poll_new(room_state.id, 900, parent_entity.id)

        room_state =
          room_state
          |> Map.put(:room_level, 900)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)
          |> insert_new_entity_to_room_state(
            "action_type",
            "청원서 보내기",
            "10000",
            poll.entity_parent_id
          )
          |> insert_new_entity_to_room_state(
            "action_type",
            "온라인 캠페인 열기",
            "20000",
            poll.entity_parent_id
          )
          |> Map.put(:vote_only, true)
          |> Map.put(:vote_enabled, true)

        # |> insert_new_entity_to_room_state("action_type", "집회 열기", "30000", poll.entity_parent_id)
        # |> insert_new_entity_to_room_state("action_type", "정보 조사", "40000", poll.entity_parent_id)

        # entities = Room.Server.entities_with(room_state, poll.entity_parent_id, "action_type")
        # for entity <- entities do
        #   Room.Server.message_new(room_state.id, "entity", "Bot", entity.type, entity: entity)
        # end

        Room.Server.broadcast_state(room_state.id)
        room_state
    end
  end

  defp poll_new_by_room_state(%{room_level: 900, id: id} = room_state) do
    # 실행 방향 고르기 후 디스패치

    elected_entity =
      case consensus_from_poll(room_state) do
        {:consensus, one} ->
          one.entity

        {:tie, first, second} ->
          first.entity
          # {:no_consensus} -> WE can't expect this at this point
      end

    case elected_entity.reference do
      "10000" ->
        Room.Server.save_room_state_to_db(room_state.id)

        parent_entity = one_entity_from_parent(room_state, "action_type", elected_entity)
        {:ok, poll} = poll_new(room_state.id, 10000, parent_entity.id)

        room_state =
          room_state
          |> Map.put(:room_level, 10000)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)
          |> Map.put(:vote_only, false)
          |> Map.put(:vote_enabled, false)

        Room.Server.broadcast_state(room_state.id)
        room_state

      "20000" ->
        Room.Server.save_room_state_to_db(room_state.id)

        parent_entity = one_entity_from_parent(room_state, "action_type", elected_entity)
        {:ok, poll} = poll_new(room_state.id, 20000, parent_entity.id)

        room_state =
          room_state
          |> Map.put(:room_level, 20000)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)
          |> Map.put(:vote_only, false)
          |> Map.put(:vote_enabled, false)

        Room.Server.broadcast_state(room_state.id)
        room_state
    end
  end

  # 청원보내기
  defp poll_new_by_room_state(%{room_level: 10000, id: id} = room_state) do
    # 피청원인의 이름을 고른후 이 사람의 직함 고르기

    elected_entity =
      case consensus_from_poll(room_state) do
        {:consensus, one} ->
          one.entity

        {:tie, first, second} ->
          first.entity
          # {:no_consensus} -> WE can't expect this at this point
      end

    # 직함
    db_result = poll_new(room_state.id, 11000, elected_entity.id)

    case db_result do
      {:ok, poll} ->
        Room.Server.save_room_state_to_db(room_state.id)

        room_state =
          room_state
          |> Map.put(:room_level, 11000)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)
          |> Map.put(:vote_only, false)
          |> Map.put(:vote_enabled, false)

        Room.Server.broadcast_state(room_state.id)
        room_state

      _ ->
        room_state
    end
  end

  defp poll_new_by_room_state(%{room_level: 11000, id: id} = room_state) do
    # 피청원인의 직함을 고른후 이 사람의 연락처 고르기

    elected_entity =
      case consensus_from_poll(room_state) do
        {:consensus, one} ->
          one.entity

        {:tie, first, second} ->
          first.entity
          # {:no_consensus} -> WE can't expect this at this point
      end

    # 연락처
    db_result = poll_new(room_state.id, 12000, elected_entity.id)

    case db_result do
      {:ok, poll} ->
        Room.Server.save_room_state_to_db(room_state.id)

        room_state =
          room_state
          |> Map.put(:room_level, 12000)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)
          |> Map.put(:vote_only, false)
          |> Map.put(:vote_enabled, false)

        Room.Server.broadcast_state(room_state.id)
        room_state

      _ ->
        room_state
    end
  end

  defp poll_new_by_room_state(%{room_level: 12000, id: id} = room_state) do
    # 이 사람의 연락처 고르기 후 토론 종결

    elected_entity =
      case consensus_from_poll(room_state) do
        {:consensus, one} ->
          one.entity

        {:tie, first, second} ->
          first.entity
          # {:no_consensus} -> WE can't expect this at this point
      end

    # 토론 끝
    db_result = poll_new(room_state.id, 100_000, elected_entity.id)

    case db_result do
      {:ok, poll} ->
        Room.Server.save_room_state_to_db(room_state.id)

        room_state =
          room_state
          |> Map.put(:room_level, 100_000)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)
          |> Map.put(:vote_only, false)
          |> Map.put(:vote_enabled, false)

        Room.Server.message_new(room_state.id, "agenda", "Bot", poll.title)
        Room.Server.message_new(room_state.id, "green", "Bot", "Please proceed to following survey url and get your reward code")
        Room.Server.message_new(room_state.id, "reward", "Bot", "Reward link here")
        Room.Server.broadcast_state(room_state.id)
        room_state

      _ ->
        room_state
    end
  end

  # 캠페인

  defp poll_new_by_room_state(%{room_level: 20000, id: id} = room_state) do
    # 캠페인 타이틀 고른 후 홍보채널 고르기

    elected_entity =
      case consensus_from_poll(room_state) do
        {:consensus, one} ->
          one.entity

        {:tie, first, second} ->
          first.entity
          # {:no_consensus} -> WE can't expect this at this point
      end

    # 홍보채널
    db_result = poll_new(room_state.id, 21000, elected_entity.id)

    case db_result do
      {:ok, poll} ->
        Room.Server.save_room_state_to_db(room_state.id)

        room_state =
          room_state
          |> Map.put(:room_level, 21000)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)
          |> Map.put(:vote_only, false)
          |> Map.put(:vote_enabled, false)

        Room.Server.broadcast_state(room_state.id)
        room_state

      _ ->
        room_state
    end
  end

  defp poll_new_by_room_state(%{room_level: 21000, id: id} = room_state) do
    # 홍보채널 후 토론 종결

    elected_entity =
      case consensus_from_poll(room_state) do
        {:consensus, one} ->
          one.entity

        {:tie, first, second} ->
          first.entity
          # {:no_consensus} -> WE can't expect this at this point
      end

    # 토론 끝
    db_result = poll_new(room_state.id, 100_000, elected_entity.id)

    case db_result do
      {:ok, poll} ->
        Room.Server.save_room_state_to_db(room_state.id)

        room_state =
          room_state
          |> Map.put(:room_level, 100_000)
          |> Map.put(:polls, Map.put(room_state.polls, poll.id, poll))
          |> Map.put(:poll, poll)
          |> Map.put(:vote_only, false)
          |> Map.put(:vote_enabled, false)

        Room.Server.message_new(room_state.id, "agenda", "Bot", poll.title)
        Room.Server.message_new(room_state.id, "green", "Bot", "Please proceed to following survey url and get your reward code")
        Room.Server.message_new(room_state.id, "reward", "Bot", "Reward link here")
        Room.Server.broadcast_state(room_state.id)
        room_state

      _ ->
        room_state
    end
  end

  defp poll_new_by_room_state(%{room_level: 100_000, id: id} = room_state) do
    # 모든 토론의 끝
    room_state
  end

  def insert_new_entity_to_room_state(
         room_state,
         entity_type,
         entity_title,
         reference,
         entity_parent_id
       ) do
    dup_list =
      Room.Server.list_entity_by_parent(room_state, entity_type, entity_parent_id)
      |> Enum.filter(fn entity -> entity.title == entity_title end)

    # If there are same entity title that has same entity title and parent and it does nothing
    case dup_list do
      [] ->
        {:ok, entity} =
          Entity.Query.new(room_state.id, entity_type, entity_title, reference, entity_parent_id)

        %{room_state | entities: Map.put(room_state.entities, entity.id, entity)}

      _ ->
        room_state
    end
  end

  defp one_entity_from_parent(room_state, type, nil), do: nil

  defp one_entity_from_parent(room_state, type, entity) do
    if entity.type == type do
      entity
    else
      one_entity_from_parent(room_state, type, Map.get(room_state.entities, entity.parent_id))
    end
  end

  defp poll_new_by_room_state(room_state) do
    room_state
  end

  defp mod_room_state({:ok, poll}, :db_op, state) do
    %{state | poll: poll}
  end

  defp mod_room_state(nil, :db_op, state), do: state
  defp mod_room_state(poll, :poll, state), do: %{state | poll: poll}

  def force_move(room_state) do
    poll_new_by_room_state(room_state)
  end
end
