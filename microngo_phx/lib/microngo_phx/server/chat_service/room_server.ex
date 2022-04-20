defmodule Room.Server do
  alias Room.Server
  alias Discussion.Topics
  alias Discussion.Topic

  defstruct id: nil,
            locale: "ko",
            room_title: "ChatToAction",
            room_level: 0,
            condition: 0,
            previous_poll: nil,
            poll: nil,
            polls: %{},
            accepting: "problem",
            polling: "problem",
            problems: %{},
            problem_seq: 1,
            entities: %{},
            entity_cursor: nil,
            votes: %{},
            users: %{},
            tutorial_users: [],
            reserved: [],
            target_members: 5,
            disconnecting_users: %{},
            timer: nil,
            presence: %{},
            started: false,
            duration: 20,
            enabled: true,
            start_at: nil,
            redeem_code_waiting: "",
            redeem_code_done: "",
            in_tutorial: false,
            bot_pid: nil,
            next_name_counter: 0,
            topic_sentence: "",
            commands: [],
            promotes: %{},
            goals: [],
            vote_only: false,
            vote_enabled: false,
            vote_mode_votes: [],
            topics: %{},
            topic_page: 0,
            moderatorTemplates: [],
            moderator_id: nil,
            connections: %{},
            advises: [],
            prompt_server_new_idea: nil,
            prompt_user_idle_server: nil,
            prompt_time_management_server: nil

  use GenServer

  def start_link(id) when is_number(id) do
    name = via_tuple(id)
    GenServer.start_link(__MODULE__, id, name: name)
  end

  defp via_tuple(room_id) do
    {:via, Registry, {:room_registry, room_id}}
  end

  defp after_init(room_id) do
    GenServer.cast(via_tuple(room_id), {:after_init})
  end

  # Client Functions

  def process_poll_request(roomid) do
    GenServer.cast(via_tuple(roomid), {:process_poll_request})
  end

  def broadcast_upstream(roomid, payload) do
    GenServer.cast(via_tuple(roomid), {:broadcast_upstream, payload})
  end

  @spec message_new(any(), any(), any(), any(), any()) :: :ok
  def message_new(roomid, kind, name, text, opt_key \\ []) do
    GenServer.cast(via_tuple(roomid), {:message_new, kind, name, text, opt_key})
  end

  def log(roomid, text) do
    GenServer.cast(via_tuple(roomid), {:log, text})
  end

  def activity(roomid, message) do
    GenServer.cast(via_tuple(roomid), {:activity, message})
  end

  def entity_new(room_id, type, title, reference, force, username) do
    GenServer.call(via_tuple(room_id), {:entity_new, type, title, reference, force, username})
  end

  def entity_broadcast(room_id, entity_id) do
    GenServer.cast(via_tuple(room_id), {:entity_broadcast, entity_id})
  end

  def problem_new(roomid, title) do
    GenServer.call(via_tuple(roomid), {:problem_new, title})
  end

  def problem_broadcast_one(roomid, problem_id) do
    GenServer.cast(via_tuple(roomid), {:problem_broadcast_one, problem_id})
  end

  def get_state(roomid) do
    GenServer.call(via_tuple(roomid), {:get_state})
  end

  def get_room_state(roomid) do
    GenServer.call(via_tuple(roomid), {:get_room_state})
  end

  def broadcast_state(roomid) do
    GenServer.cast(via_tuple(roomid), {:broadcast_state})
  end

  def save_room_state_to_db(roomid) do
    GenServer.cast(via_tuple(roomid), {:save_room_state_to_db})
  end

  def poll_vote(room_id, poll_id, entity_id, user_id, value) do
    GenServer.cast(via_tuple(room_id), {:poll_vote, poll_id, entity_id, user_id, value})
  end

  def login(room_id, user_entity) do
    GenServer.call(via_tuple(room_id), {:login, user_entity})
  end

  def put_presence(room_id, data) do
    GenServer.cast(via_tuple(room_id), {:put_presence, data})
  end

  # @spec put_disconnecting(number(), number())
  def disconnecting(room_id, user_id) do
    GenServer.cast(via_tuple(room_id), {:disconnecting, user_id})
  end

  def disconnect(room_id, user_id) do
    GenServer.cast(via_tuple(room_id), {:disconnect, user_id})
  end

  def force_next(room_id) do
    GenServer.cast(via_tuple(room_id), :force_next)
  end

  def is_new_member_allowed(room_id) do
    GenServer.call(via_tuple(room_id), {:is_new_member_allowed?})
  end

  def reserve(room_id) do
    GenServer.cast(via_tuple(room_id), {:reserve})
  end

  def tutorial_done(room_id, user_id) do
    GenServer.cast(via_tuple(room_id), {:tutorial_done, user_id})
  end

  def next_username(room_id) do
    GenServer.call(via_tuple(room_id), {:next_username})
  end

  def set_topic_sentence(room_id, topic_sentence) do
    GenServer.cast(via_tuple(room_id), {:set_topic_sentence, topic_sentence})
  end

  def previous_messages(room_id, from_id) do
    GenServer.call(via_tuple(room_id), {:previous_messages, room_id, from_id})
  end

  def get_poll(room_id) do
    GenServer.call(via_tuple(room_id), {:get_poll})
  end

  def room_level(room_id) do
    GenServer.call(via_tuple(room_id), {:room_level})
  end

  def proceed(room_id) do
    GenServer.cast(via_tuple(room_id), {:proceed})
  end

  def promote(room_id, message, username) do
    GenServer.cast(via_tuple(room_id), {:promote, message, username})
  end

  def vote_mode_vote(room_id, username, value) do
    GenServer.cast(via_tuple(room_id), {:vote_mode_vote, username, value})
  end

  def new_topic_above(room_id, from_name, new_topic_name) do
    GenServer.cast(via_tuple(room_id), {:new_topic_above, from_name, new_topic_name})
  end

  def new_topic_below(room_id, from_name, new_topic_name) do
    GenServer.cast(via_tuple(room_id), {:new_topic_below, from_name, new_topic_name})
  end

  def add_an_answer_to_topic(room_id, topic_name, answer_name) do
    GenServer.cast(via_tuple(room_id), {:add_an_answer_to_topic, topic_name, answer_name})
  end

  def start_voting_on_topic(room_id, topic_name) do
    GenServer.cast(via_tuple(room_id), {:start_voting_on_topic, topic_name})
  end

  def vote_on_answer(room_id, topic_name, answer_name, user_name, up) do
    GenServer.cast(via_tuple(room_id), {:vote_on_answer, topic_name, answer_name, user_name, up})
  end

  def mark_as_done(room_id, topic_name) do
    GenServer.cast(via_tuple(room_id), {:mark_as_done, topic_name})
  end

  def reopen(room_id, topic_name) do
    GenServer.cast(via_tuple(room_id), {:reopen, topic_name})
  end

  def focus(room_id, topic_name) do
    GenServer.cast(via_tuple(room_id), {:focus, topic_name})
  end

  def delete_answer(room_id, topic_name, answer_name) do
    GenServer.cast(via_tuple(room_id), {:delete_answer, topic_name, answer_name})
  end

  def add_topics(room_id, topic_names) do
    GenServer.cast(via_tuple(room_id), {:add_topics, topic_names})
  end

  def start(room_id) do
    GenServer.cast(via_tuple(room_id), {:start})
  end

  def finish(room_id) do
    GenServer.cast(via_tuple(room_id), {:finish})
  end

  def add_advice(room_id, advice) do
    GenServer.cast(via_tuple(room_id), {:add_advice, advice})
  end

  def add_message_action(room_id, message_id, kind, title) do
    GenServer.cast(via_tuple(room_id), {:add_message_action, message_id, kind, title})
  end

  def designate_moderator(room_id, user_id) do
    GenServer.cast(via_tuple(room_id), {:designate_moderator, user_id})
  end

  def enabled(room_id, enabled) do
    GenServer.cast(via_tuple(room_id), {:enabled, enabled})
  end

  def crash(room_id) do
    GenServer.cast(via_tuple(room_id), {:crash})
  end

  ###############################################

  def init(id) do
    IO.puts("room started " <> Integer.to_string(id))
    after_init(id)
    {:ok, %Room.Server{id: id}}
  end

  # info
  def handle_info(:bot_timer, room_state) do
    Process.send_after(self(), :bot_timer, 180_000)

    # if room_state.poll != nil do
    #   entities = entities_with(room_state, room_state.poll.entity_parent_id, room_state.poll.entity_type)
    #   if entities == [] do
    #     Room.Server.message_new(
    #       room_state.id,
    #       "please_add_candidates",
    #       "Bot",
    #       "Please add candidate by pressing Plus(+) button at the bottom of the chatroom"
    #     )
    #   else
    #     Room.Server.message_new(
    #       room_state.id,
    #       "please_make_votes",
    #       "Bot",
    #       "Please vote if you spotted a nice candidate!"
    #     )
    #   end
    # end

    {:noreply, room_state}
  end

  # def handle_info(:change_moderator, room_state) do
  #   moderator_presence = Map.get(room_state.users, room_state.moderator_id)
  #   if moderator_presence == nil do
  #     new_elect = Enum.at(room_state.users, 0)
  #     if new_elect == nil do
  #       {:noreply, %{room_state|
  #         moderator_id: nil
  #       }}
  #     else
  #       {id, user} = new_elect
  #       message_new(room_state.id, "green", "Bot", "모더레이터가 #{user.username}님으로 자동선출 되었습니다.")
  #       message_new(room_state.id, "green", "Bot", "모더레이터가 #{user.username}님께서는 화면 오른쪽 상단의 튜토리얼 보기를 통해 사회진행자의 권한과 기능을 살펴봐주시기 바랍니다.")
  #       broadcast_state(room_state.id)
  #       {:noreply, %{room_state|
  #         moderator_id: id,
  #       }}
  #     end
  #   else
  #     {:noreply, room_state}
  #   end
  # end

  def handle_info(:waiting_due, room_state) do
    if room_state.started == false do
      # Room.Server.message_new(room_state.id, "agenda", "Bot", "Session Ended")
      # Room.Server.message_new(
      #   room_state.id,
      #   "normal",
      #   "Bot",
      #   "Thanks for your waiting. I don't think this session will going to happen But here is your reward code"
      # )
      # Room.Server.message_new(room_state.id, "normal", "Bot", "#{room_state.redeem_code_waiting}")
      # broadcast_state(room_state.id)
      {:noreply, room_state}
    else
      {:noreply, room_state}
    end
  end

  def handle_info(:reserve_expired, room_state) do
    if Enum.count(room_state.reserved) > 0 do
      [h | t] = room_state.reserved
      # Process.cancel_timer(h)
      {:noreply, %{room_state | reserved: t}}
    else
      {:noreply, room_state}
    end
  end

  # CASTS

  def handle_cast({:enabled, enabled}, state) do
    broadcast_state(state.id)
    save_room_state_to_db(state.id)
    {:noreply, %{state|
        enabled: enabled
    }}
  end

  def handle_cast({:designate_moderator, user_id}, state) do
    broadcast_state(state.id)
    save_room_state_to_db(state.id)
    {:noreply, %{state|
        moderator_id: user_id
    }}
  end

  def handle_cast({:proceed}, state) do
    if state.vote_enabled == false do
      new_state = %{state|
        vote_enabled: true,
        vote_mode_votes: []
      }
      message_new(state.id, "normal", "Bot", "It's voting time!")
      message_new(state.id, "entity", "Bot", "Please vote to pick our best answer")

      broadcast_state(state.id)
      {:noreply, new_state}
    else
      Room.Poll.force_move(state)
      {:noreply, state}
    end
  end

  def handle_cast({:promote, message, username}, state) do
    promotes = state.promotes
    |> Map.get_and_update(message, fn(votes) ->
      if votes == nil do
        new_votes = [username]
        broadcast_state(state.id)
        {votes, new_votes}
      else
        IO.inspect Enum.find(votes, fn(x) -> x == username end)
        new_votes = if Enum.find(votes, fn(x) -> x == username end) == nil do
          broadcast_state(state.id)
          votes ++ [username]
        else
          votes
        end
        {votes, new_votes}
      end
    end) |> elem(1)
    IO.inspect promotes

    goals = state.goals
    goal_idx = Enum.find_index(goals, fn(x) -> x.action == "brainstorming" end)
    goals = if goal_idx == nil do
      goals
    else
      List.update_at(goals, goal_idx, fn(x) ->
        %{x|
          current: Enum.count(promotes)
        }
      end)
    end

    new_state = %{state|
      promotes: promotes,
      goals: goals
    }

    {:noreply, new_state}
  end

  def handle_cast({:set_topic_sentence, topic_sentence}, state) do
    next_state = %{state|
      topic_sentence: topic_sentence
    }
    # IO.puts "new topic sentence #{topic_sentence}"
    # add_advice(state.id, %Advice{
    #   kind: "prompt_compliment", title: "의견이 표명되면 고맙다고 해보세요", body: "의견을 두려움 없이 나눌 수 있는 토론 분위기가 토론 품질을 높입니다", message: "좋은 의견 감사합니다."
    # })
    broadcast_state(state.id)
    {:noreply, next_state}
  end

  def handle_cast(:force_next, state) do
    {:noreply, Room.Poll.force_move(state)}
  end

  def handle_cast({:after_init}, state) do
    IO.puts("After Init " <> stat_topic(state))

    commands = [
      %Command{
        message: "Let's proceed",
        action: "force_next",
        action_text: "Bot will proceed to next discussion phase",
        target: 3,
        votes: []
      }
    ]
    goals = [
      %Goal{
        message: "10 possible answers for the question",
        action: "brainstorming",
        target: 10,
        current: 0
      }
    ]

    seed_topics = Topics.new()
    |> Discussion.Topics.new_topic("토의가 준비되었으면 시작하세요!", kind: "start" , page: 0, placeholder: "")
    |> Discussion.Topics.new_topic("이 문제가 없는 최상의 상태를 한문장으로 적으면 무엇입니까?", kind: "goal" , page: 0, placeholder: "목표는 ... 입니다")
    |> Discussion.Topics.new_topic("최상의 상태를 막는 원인은 무엇입니까?", kind: "cause", page: 0, placeholder: "한계점은 ... 입니다")
    |> Discussion.Topics.new_topic("그 원인의 증거는 무엇입니까?", kind: "cause_evidence", page: 0, placeholder: "한계점은 ... 입니다")
    |> Discussion.Topics.new_topic("어떤 해결책이 있습니까?", kind: "solution", page: 1,  placeholder: "해결책은 ... 입니다")
    |> Discussion.Topics.new_topic("해결책의 장점은 무엇인가요?", kind: "solution_pro", page: 1, placeholder: "장점은 ... 입니다")
    |> Discussion.Topics.new_topic("해결책의 단점은 무엇인가요?", kind: "solution_con", page: 1, placeholder: "단점은 ... 입니다")
    |> Discussion.Topics.new_topic("다른 해결책보다 이 해결책이 나은이유는 무엇인가요?", kind: "solution_reason", page: 1, placeholder: ".. 와 비교해서 .. 습니다")
    |> Discussion.Topics.focus("토의가 준비되었으면 시작하세요!")

    # Check Poll is properly spawn

    state = case ChatService.StashServer.fetch(state.id) do
      nil ->
        state
        |> room_state_from_db()
        |> start_timer_init()
        |> Room.Poll.load_polls_from_db()
        |> Room.Poll.load_state_of_last_poll_from_db()
        |> Room.Entity.init_entity_check()
        |> Room.Vote.init_load()
        |> Room.Poll.process_poll()
        |> room_state_add_bot()
        |> Map.put(:commands, commands)
        |> Map.put(:goals, goals)
      stashed_state ->
        stashed_state
    end

    state = if state.topics == nil do
      Map.put(state, :topics, seed_topics)
    else
      state
    end

    broadcast_state(state.id)
    # init event braodcast
    MicrongoPhxWeb.Endpoint.broadcast(stat_channel_name(state), "init", %{
      init: true
    })

    # prompt_server_new_idea
    {:ok, pid} = Prompt.NewIdeaServer.start_link(interval: 60000, room_id: state.id)
    state = %{state|
      prompt_server_new_idea: pid
    }

    {:ok, pid} = Prompt.UserIdleServer.start_link(interval: 60000, room_id: state.id)
    state = %{state|
      prompt_user_idle_server: pid
    }

    {:ok, pid} = Prompt.TimeManagementServer.start_link(interval: 180000, room_id: state.id)
    state = %{state|
      prompt_time_management_server: pid
    }

    {:noreply, state}
  end

  def handle_cast({:broadcast_upstream, event}, state) do
    IO.puts("Broadcasting Event " <> event.event_name)

    MicrongoPhxWeb.Endpoint.broadcast(
      "stat:" <> Integer.to_string(state.id),
      event.event_name,
      event.payload
    )

    {:noreply, state}
  end

  def handle_cast({:message_new, kind, name, text, opt_key}, room_state) do
    text = String.trim(text)
    if text != "" do
      user_id = Keyword.get(opt_key, :user_id)
      vote_position =
        if user_id == nil do
          "Undecided"
        else
          vote =
            Enum.reduce(room_state.votes, nil, fn {_, v}, a ->
              if v.poll_id == room_state.poll.id && v.user_id == user_id do
                v
              else
                a
              end
            end)

          if vote == nil do
            "Undecided"
          else
            case Map.get(room_state.entities, vote.entity_id) do
              nil -> "Undecided"
              entity -> entity.title
            end
          end
        end

      poll_id =
        case Keyword.get(opt_key, :poll_id) do
          nil ->
            case room_state.poll do
              nil -> nil
              poll -> poll.id
            end
          x -> x
        end

      command = nil

      target_command_idx = Enum.find_index(room_state.commands, fn(x) -> x.action == command  end)
      new_commands = if target_command_idx == nil do
        room_state.commands
      else
        List.update_at(room_state.commands, target_command_idx, fn(comm) ->
          vote_exist = Enum.find(comm.votes, fn(x) -> x == name end)
          if vote_exist == nil do
            broadcast_state(room_state.id)
            %{comm|
              votes: comm.votes ++ [name]
            }
          else
            comm
          end
        end)
      end

      force_next = Enum.find(room_state.commands, fn(x) -> x.action == "force_next"  end)
      if force_next != nil and  force_next.target <= Enum.count(force_next.votes) do
        Room.Server.proceed(room_state.id)
      end

      new_state = %{room_state|
        commands: new_commands
      }

      param = %{
        kind: kind,
        name: name,
        room_id: room_state.id,
        user_id: Keyword.get(opt_key, :user_id),
        text: text,
        entity: Keyword.get(opt_key, :entity),
        vote_position: vote_position,
        poll_id: poll_id,
        command: command,
        parent: Keyword.get(opt_key, :parent)
      }

      changeset = DB.Message.changeset(%DB.Message{}, param)
      {:ok, message} = MicrongoPhx.Repo.insert(changeset)
      message = Message.Logic.after_load(message)

      spawn(fn ->
        user_id = Keyword.get(opt_key, :user_id)
        if kind == "normal" && name != "Bot" do
          if user_id != room_state.moderator_id do
            Prompt.UserIdleServer.user_say(room_state.prompt_user_idle_server, name)
          end

          query = NLU.query(text)
          if NLU.Result.intent_name(query) != nil do
            Room.Server.log(room_state.id, "NLU Result for #{message.id} = " <> (NLU.Result.intent_name(query) || "nil"))
          end
          IO.puts NLU.Result.intent_name(query)
          topic = Discussion.Topics.get_topic(room_state.topics, Discussion.Topics.current_topic_name(room_state.topics))
          IO.puts topic["kind"]



          if NLU.Result.intent_name(query) == "user_adding" && user_id != room_state.moderator_id  do
            Room.Server.set_topic_sentence(room_state.id, text)
            Room.Server.add_message_action(room_state.id, message.id, "답변추천:", "그렇군요")
            Room.Server.add_message_action(room_state.id, message.id, "답변추천:", "좀 더 설명해주실 수 있나요?")
            Room.Server.add_message_action(room_state.id, message.id, "답변추천:", "증거가 있나요?")
            Room.Server.add_message_action(room_state.id, message.id, "답변추천:", "의견 감사합니다")
            # add_advice(new_state.id, %Advice{
            #   kind: "prompt_new_idea", title: "많은 아이디어가 나오도록 독려하세요", body: "많은 의견은 토론 품질을 높혀줍니다", message: "다른 의견은 없으신가요?"
            # })
            Prompt.NewIdeaServer.postpond(new_state.prompt_server_new_idea)
          end

          if NLU.Result.intent_name(query) == "user_category"  do
            Room.Server.set_topic_sentence(room_state.id, text)
            Room.Server.add_message_action(room_state.id, message.id, "답변추천:", "그 내용에 대해 지금 순서를 만들어 자세히 이야기해볼까요?")
          end

          if user_id == room_state.moderator_id do
            case NLU.Result.intent_name(query) do
              # "stage_01_goal" ->
              #   add_advice(room_state.id, %Advice{
              #     kind: "prompt_topic_guide",
              #     title: "이 순서를 소개해보세요",
              #     body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
              #     message: "이번 순서는 우리가 원하는 문제가 풀렸을때의 최상의 상태를 찾아보는 순서입니다. 우리가 지향하는 목표를 찾고 그것을 방해하는 요소를 다음에 찾아볼겁니다."
              #   })
              # "stage_02_cause" ->
              #   add_advice(room_state.id, %Advice{
              #     kind: "prompt_topic_guide",
              #     title: "이 순서를 소개해보세요",
              #     body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
              #     message: "이번 순서는 우리가 원하는 그 상태를 방해하는 원인들을 찾는 시간입니다. 그 원인들을 찾고나면 다음순서에서 그 원인을 위한 증거를 찾을겁니다."
              #   })
              # "stage_03_cause_evidence" ->
              #   add_advice(room_state.id, %Advice{
              #     kind: "prompt_topic_guide",
              #     title: "이 순서를 소개해보세요",
              #     body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
              #     message: "이번 순서는 방금찾은 원인에 대해 증거를 찾아보는 시간입니다. 이 원인이 확실히 증거로 받침되어야 다음순서에서 해결책을 찾을 때 수월합니다."
              #   })
              # "stage_04_solution" ->
              #   add_advice(room_state.id, %Advice{
              #     kind: "prompt_topic_guide",
              #     title: "이 순서를 소개해보세요",
              #     body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
              #     message: "이번순서는 해결책을 찾아보는 시간입니다 아까 찾은 원인을 위한 해결책을 찾아봅시다."
              #   })
              # "stage_05_solution_pro" ->
              #   add_advice(room_state.id, %Advice{
              #     kind: "prompt_topic_guide",
              #     title: "이 순서를 소개해보세요",
              #     body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
              #     message: "이번 순서는 해결책의 장점을 살펴보는 시간입니다. 단점은 다음 순서에서 다룰겁니다."
              #   })
              # "stage_06_solution_con" ->
              #   add_advice(room_state.id, %Advice{
              #     kind: "prompt_topic_guide",
              #     title: "이 순서를 소개해보세요",
              #     body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
              #     message: "이번 순서는 해결책의 단점을 살펴보는 시간입니다. 단점이 장점을 넘어선다면 좋은 해결책이 아닙니다. 다음 순서에서는 솔루션 선택의 정당성을 이야기 해볼겁니다."
              #   })
              # "stage_07_solution_reason" ->
              #   add_advice(room_state.id, %Advice{
              #     kind: "prompt_topic_guide",
              #     title: "이 순서를 소개해보세요",
              #     body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
              #     message: "이번 순서에서는 왜 반드시 이 해결책이어야 하는지 정당성 발굴해내는 시간입니다. 해결책은 반드시 다른 해결책보다 나음을 잘 증명해낼 수 있어야 합니다."
              #   })
              "prompt_compliment" ->
                add_advice(room_state.id, %Advice{
                  kind: "prompt_compliment-done", title: "의견 표명을 칭찬하였습니다", body: text, message: text
                })
              "prompt_group_think" ->
                add_advice(room_state.id, %Advice{
                  kind: "prompt_group_think-done", title: "편향된 의견 방지를 시도했습니다", body: text, message: text
                })
              "prompt_new_idea" ->
                add_advice(room_state.id, %Advice{
                  kind: "prompt_new_idea-done", title: "다양한 의견을 독려했습니다", body: text, message: text
                })
              "prompt_next" ->
                add_advice(room_state.id, %Advice{
                  kind: "prompt_next-done", title: "다음순서로 진행을 시도했습니다", body: text, message: text
                })
              "prompt_objective_idea" ->
                add_advice(room_state.id, %Advice{
                  kind: "prompt_objective_idea-done", title: "객관적인 정보에 근거한 의견을 유도했습니다", body: text, message: text
                })
              "prompt_reduce_scope" ->
                add_advice(room_state.id, %Advice{
                  kind: "prompt_reduce_scope-done", title: "토론 범위를 축소를 시도했습니다", body: text, message: text
                })
              "prompt_topic_guide" ->
                add_advice(room_state.id, %Advice{
                  kind: "prompt_topic_guide-done", title: "토론 순서를 소개했습니다", body: text, message: text
                })
              "prompt_vote" ->
                add_advice(room_state.id, %Advice{
                  kind: "prompt_vote-done", title: "투표를 유도했습니다", body: text, message: text
                })
              _ -> nil
            end
          end
        end
      end)

      # if room_state.condition == 3 && kind == "normal" && room_state.bot_pid != nil && name != "Bot" do
      #   {count, score} = NGOBot.talk(room_state.bot_pid, text)
      #   if count > 10 && score == 0 do
      #     Room.Server.add_message_action(room_state.id, message.id, "답변추천:", "주제에 집중해주시면 감사하겠습니다")
      #   end
      # end

      MicrongoPhxWeb.Endpoint.broadcast(stat_channel_name(room_state), "message", %{
        messages: [message]
      })

      {:noreply, new_state}
    else
      {:noreply, room_state}
    end
  end

  def handle_cast({:log, text}, room_state) do
    text = case String.trim(text) do
      "" -> "Blank"
      x -> x
    end

    param = %{
      kind: "log",
      name: "logger",
      room_id: room_state.id,
      user_id: nil,
      text: text,
      entity: nil,
      vote_position: nil,
      poll_id: nil,
      command: nil,
      parent: nil
    }

    changeset = DB.Message.changeset(%DB.Message{}, param)
    {:ok, _message} = MicrongoPhx.Repo.insert(changeset)
    # message = Message.Logic.after_load(message)

    {:noreply, room_state}
  end

  def handle_cast({:problem_broadcast_one, problem_id}, room_state) do
    problems =
      Problem.Logic.all_by_param(id: problem_id)
      |> Problem.Logic.safe_map_list()

    MicrongoPhxWeb.Endpoint.broadcast(stat_topic(room_state), "problems", %{problems: problems})
    {:noreply, room_state}
  end

  def handle_cast({:entity_broadcast, entity_id}, room_state) do
    case Entity.Query.get_by_id(entity_id) do
      nil ->
        nil

      %Entity{} = entity ->
        MicrongoPhxWeb.Endpoint.broadcast(stat_topic(room_state), "entities", %{
          entities: [entity]
        })
    end

    {:noreply, room_state}
  end

  def handle_cast({:poll_vote, poll_id, entity_id, user_id, value}, room_state) do
    changes = Vote.Query.vote(poll_id, entity_id, user_id, value)

    current_poll_id = if room_state.poll == nil do
      nil
    else
      room_state.poll.id
    end

    state =
      mod_state_for_vote_change(changes, room_state)
      |> Room.Poll.process_poll()

    MicrongoPhxWeb.Endpoint.broadcast(stat_channel_name(room_state), "votes", %{
      vote_events: changes
    })

    new_poll_id = if state.poll == nil do
      nil
    else
      state.poll.id
    end

    state = if (current_poll_id != new_poll_id ) do
      if (state.poll.entity_type == "route" or state.poll.entity_type == "action_type") do
        %{state|
          vote_enabled: true,
          vote_only: true,
          vote_mode_votes: []
        }
      else
        %{state|
          vote_enabled: false,
          vote_mode_votes: []
        }
      end
    else
      state
    end

    broadcast_state(room_state.id)
    {:noreply, state}
  end

  def handle_cast({:broadcast_state}, room_state) do
    broadcasting = sanitize_room_state(room_state)

    MicrongoPhxWeb.Endpoint.broadcast(
      stat_channel_name(room_state),
      "get_room_state",
      broadcasting
    )

    {:noreply, room_state}
  end

  def handle_cast({:save_room_state_to_db}, room_state) do
    Room.Query.update_by_room_state(room_state)
    ChatService.StashServer.stash(room_state.id, room_state)
    {:noreply, room_state}
  end

  def handle_cast({:put_presence, data}, room_state) do
    {:noreply, %Server{room_state | presence: data}}
  end

  def handle_cast({:disconnecting, user_id}, room_state) do
    # case Map.get(room_state.users, user_id) do
    #   nil -> {:noreply, room_state}
    #   user ->
    #     Room.Server.message_new(room_state.id, "disconnecting", "Bot", user.username)

    #     #Killing Existing Waiter
    #     case (room_state.disconnecting_users
    #       |> Map.get(user_id, nil)) do
    #       nil -> nil
    #       ex_pid -> Process.exit(ex_pid, :kill)
    #     end
    #     #Spawn New waiter
    #     pid = spawn fn ->
    #       Process.send_after(self(), :waiting_due, 10_000)
    #       receive do
    #         :waiting_due ->
    #           Room.Server.disconnect(room_state.id, user_id)
    #         x -> IO.inspect x
    #       end
    #     end
    #     #Record Pid
    #     {:noreply, %Room.Server{room_state|
    #       disconnecting_users: (room_state.disconnecting_users
    #       |> Map.put(user_id, pid))
    #     }}
    # end

    case Map.get(room_state.users, user_id) do
      nil ->
        {:noreply, room_state}

      user ->
        user_connections = Map.get(room_state.connections, user_id, [])
        |> Enum.drop(1)

        if Enum.count(user_connections) > 0 do
          new_state = %Room.Server{room_state|
            connections: Map.put(room_state.connections, user_id, user_connections)
          }
          {:noreply, new_state}
        else
          # TODO
          # Room.Server.message_new(room_state.id, "disconnected", "Bot", user.username)
          # Searching quitting member's vote on current poll
          existing_vote =
            Enum.reduce(room_state.votes, nil, fn
              {_, vote}, nil ->
                if vote.poll_id == room_state.poll.id && vote.user_id == user_id do
                  vote
                else
                  nil
                end

              _, acc ->
                acc
            end)

          # remove vote it exist
          new_votes =
            case existing_vote do
              nil ->
                room_state.votes

              removing_vote ->
                MicrongoPhx.Repo.delete(removing_vote)
                Map.delete(room_state.votes, removing_vote.id)
            end

          # if room_state.moderator_id != nil && room_state.moderator_id == user_id do
          #   message_new(room_state.id, "green", "Bot", "진행님이 접속이 끊겼습니다. 1분뒤에 재접속이 안되는경우 새 진행자님이 자동선출됩니다")
          #   Process.send_after(self(), :change_moderator, 60_000)
          # end

          new_state =
            %Room.Server{room_state|
              users: Map.delete(room_state.users, user_id),
              votes: new_votes,
              connections: Map.put(room_state.connections, user_id, user_connections),
            }
            |> Room.Poll.process_poll()
          # schedule broadcast
          broadcast_state(room_state.id)
          # New roomstate
          {:noreply, new_state}
        end
    end
  end

  def handle_cast({:process_poll_request}, room_state) do
    {:noreply, Room.Poll.process_poll(room_state)}
  end

  def handle_cast({:reserve}, room_state) do
    {:noreply,
     %{
       room_state
       | reserved: room_state.reserved ++ [Process.send_after(self(), :reserve_expired, 60_000)]
     }}
  end

  def handle_cast({:tutorial_done, user_id}, room_state) do
    # room_state = %{
    #    room_state
    #    | tutorial_users: ((room_state.tutorial_users ++ [user_id]) |> Enum.uniq())
    #  }

    # room_state =
    #   if room_state.started == false &&
    #         Enum.count(room_state.tutorial_users) >= room_state.target_members do
    #     Room.Server.message_new(room_state.id, "green", "Bot", "The session is started!")
    #     Room.Server.save_room_state_to_db(room_state.id)
    #     Process.send_after(self(), :bot_timer, 180_000)

    #     %{room_state | started: true}
    #     |> Room.Poll.process_poll()
    #   else
    #     room_state
    #   end

    # broadcast_state(room_state.id)

    {:noreply, room_state}
  end

  def handle_cast({:vote_mode_vote, username, value}, state) do
    new_state = if value == true do
      exist = Enum.find(state.vote_mode_votes, fn(x) ->
        x == username
      end)

      new_vote_mode_votes = if exist == nil do
        broadcast_state(state.id)
        state.vote_mode_votes ++ [username]
      else
        state.vote_mode_votes
      end

      %{state|
        vote_mode_votes: new_vote_mode_votes
      }
    else
      new_vote_mode_votes = Enum.filter(state.vote_mode_votes, fn(x) -> x != username end)

      broadcast_state(state.id)

      %{state|
        vote_mode_votes: new_vote_mode_votes
      }
    end

    if Enum.count(new_state.vote_mode_votes) >= Enum.count(new_state.users) do
      #만장일치가 되면
      Room.Server.proceed(state.id)
    end

    {:noreply, new_state}
  end

  def handle_cast({:activity, message}, state) do
    MicrongoPhxWeb.Endpoint.broadcast(stat_channel_name(state), "activity", %{
      message: message
    })
    {:noreply, state}
  end

  def handle_cast({:new_topic_above, from_name, new_topic_name}, state) do
    old_topics = state.topics
    new_topics = Discussion.Topics.new_topic_above(state.topics, from_name, new_topic_name)

    new_state = %{detect_topic_change(old_topics, new_topics, state)|
      topics: new_topics
    }
    broadcast_state(state.id)
    Room.Server.save_room_state_to_db(state.id)
    {:noreply, new_state}
  end

  def handle_cast({:new_topic_below, from_name, new_topic_name}, state) do
    old_topics = state.topics
    new_topics = Discussion.Topics.new_topic_below(state.topics, from_name, new_topic_name)

    new_state = %{detect_topic_change(old_topics, new_topics, state)|
      topics: new_topics
    }
    broadcast_state(state.id)
    Room.Server.save_room_state_to_db(state.id)
    {:noreply, new_state}
  end

  def handle_cast({:add_an_answer_to_topic, topic_name, answer_name}, state) do
    new_topics = Discussion.Topics.add_an_answer_to_topic(state.topics, topic_name, answer_name)
    new_state = %{state|
      topics: new_topics
    }

    current_topic = Discussion.Topics.current_topic(new_topics)
    if current_topic != nil && Enum.count(current_topic["orders"]) >= 3 do
      add_advice(state.id, %Advice{
        kind: "prompt_group_think", title: "의견이 너무 편향적이진 않은지 살펴보세요", body: "그룹이 너무 한 의견에 치우치면, 다른 대안을 살펴보지 않는 실수를 할 수 있습니다.", message: "나온 의견들이 편향된 것은 아닌지 생각해봅시다"
      })
      add_advice(state.id, %Advice{
        kind: "prompt_vote", title: "투표를 독려하세요", body: "시간이 너무 소요되지 않으면서 한 의견에 대해 동의를 얻도록 해보세요.", message: "이제 투표를 해볼까요?"
      })
    else
      add_advice(state.id, %Advice{
        kind: "prompt_objective_idea", title: "의견들의 객관성을 확보하세요", body: "의견의 객관성은 토론품질에 중요합니다", message: "투표 후보로 등록된 의견에 대해 각각 증거를 찾아볼까요?"
      })
    end

    broadcast_state(state.id)
    Room.Server.save_room_state_to_db(state.id)
    Room.Server.log(state.id, "Add an answer: #{answer_name}")
    {:noreply, new_state}
  end

  def handle_cast({:start_voting_on_topic, topic_name}, state) do
    new_topics = Discussion.Topics.start_voting_on_topic(state.topics, topic_name)
    message_new(state.id, "normal", "진행", "우리 투표 합시다")
    message_new(state.id, "proto2_summary", "진행", topic_name)

    new_state = %{state|
      topics: new_topics
    }
    broadcast_state(state.id)
    Room.Server.save_room_state_to_db(state.id)
    {:noreply, new_state}
  end

  def handle_cast({:vote_on_answer, topic_name, answer_name, user_name, up}, state) do
    new_topics = Discussion.Topics.vote_on_answer(state.topics, topic_name, answer_name, user_name, up)
    new_state = %{state|
      topics: new_topics
    }

    current_answers = Discussion.Topics.get_topic(new_state.topics, topic_name)["answers"]

    reached? = Enum.any?(current_answers, fn ({_, v}) ->
      %{"votes" => votes} = v
      if Enum.count(votes) > Enum.count(new_state.users) * 0.50 do
        true
      else
        false
      end
    end)

    if reached? do
      add_advice(new_state.id, %Advice{
        kind: "prompt_next",
        title: "다음 순서로 유도해보세요",
        body: "의견이 잘 수렴되었다고 생각하면 다음 순서로 가보세요",
        message: "이제 다음 순서를 진행할까요?"
      })
      add_advice(new_state.id, %Advice{
        kind: "prompt_group_think",
        title: "의견이 편향되지 않았는지 체크하세요",
        body: "의견이 잘 수렴되었다고 생각하면 다음 순서로 가보세요",
        message: "수렴된 의견이 너무 편향적이진 않은지 생각해봅시다"
      })
    end

    Room.Server.log(state.id, "Vote on answer: #{topic_name} #{answer_name} #{user_name} #{up}")

    broadcast_state(state.id)
    Room.Server.save_room_state_to_db(state.id)
    {:noreply, new_state}
  end

  def handle_cast({:mark_as_done, topic_name}, state) do
    old_topics = state.topics
    new_topics = Discussion.Topics.mark_as_done(state.topics, topic_name)

    new_state = %{detect_topic_change(old_topics, new_topics, state)|
      topics: new_topics
    }
    broadcast_state(state.id)
    Room.Server.save_room_state_to_db(state.id)
    {:noreply, new_state}
  end

  def handle_cast({:reopen, topic_name}, state) do
    new_topics = Discussion.Topics.reopen(state.topics, topic_name)
    new_state = %{state|
      topics: new_topics
    }
    broadcast_state(state.id)
    Room.Server.save_room_state_to_db(state.id)
    {:noreply, new_state}
  end

  def handle_cast({:focus, topic_name}, state) do
    old_topics = state.topics
    new_topics = Discussion.Topics.focus(state.topics, topic_name)

    new_state = %{detect_topic_change(old_topics, new_topics, state)|
      topics: new_topics
    }

    broadcast_state(state.id)
    Room.Server.save_room_state_to_db(state.id)
    {:noreply, new_state}
  end

  def handle_cast({:delete_answer, topic_name, answer_name}, state) do
    new_topics = Discussion.Topics.delete_answer(state.topics, topic_name, answer_name)
    new_state = %{state|
      topics: new_topics
    }
    broadcast_state(state.id)
    Room.Server.save_room_state_to_db(state.id)
    Room.Server.log(state.id, "Delete an answer: #{answer_name}")
    {:noreply, new_state}
  end

  def handle_cast({:add_topics, topic_names}, state) do
    new_topics = Enum.reduce(topic_names, state.topics, fn(topic_name, topics) ->
      Topics.new_topic(topics, topic_name)
    end)
    first_topic = Enum.at(topic_names, 0)
    holder_topic = Topics.get_topic_by_kind(new_topics, "action_plan_start")
    new_topics = if holder_topic == nil do
      new_topics
    else
      %{new_topics|
        "orders" =>  new_topics["orders"] -- [holder_topic["name"]],
        "data" => Map.delete(new_topics["data"], holder_topic["name"]),
        "current_topic_name" => first_topic
      }
    end

    new_state = %{detect_topic_change(state.topics, new_topics, state)|
      topics: new_topics
    }

    broadcast_state(state.id)
    Room.Server.save_room_state_to_db(state.id)
    {:noreply, new_state}
  end

  def handle_cast({:start}, state) do
    new_state = %{state|
      started: true,
      start_at: Timex.now()
    }
    broadcast_state(state.id)
    {:noreply, new_state}
  end

  def handle_cast({:finish}, state) do
    new_state = %{state|
      started: false
    }
    broadcast_state(state.id)
    {:noreply, new_state}
  end

  def handle_cast({:add_advice, advice}, state) do
    new_advices = state.advises ++ [advice]
    new_state = %{state|
      advises: new_advices
    }
    %{kind: kind} = advice
    log(state.id, "Suggested for #{kind}")
    MicrongoPhxWeb.Endpoint.broadcast(stat_channel_name(state), "new_advice", advice)
    broadcast_state(state.id)
    {:noreply, new_state}
  end

  def handle_cast({:add_message_action, message_id, kind, title}, state) do
    MicrongoPhxWeb.Endpoint.broadcast(stat_channel_name(state), "add_message_action", %{
      message_id: message_id,
      kind: kind,
      title: title
    })
    {:noreply, state}
  end

  defp detect_topic_change(old_topics, new_topics, state) do
    if new_topics["current_topic_name"] == nil || new_topics["current_topic_name"] == "" do
      message_new(state.id, "reward", "진행", "토론 끝남")
      state
    else
      current_topic = Topics.get_topic(new_topics, new_topics["current_topic_name"])
      case current_topic do
        %{"kind" => "goal"} ->
          add_advice(state.id, %Advice{
            kind: "prompt_topic_guide",
            title: "이 순서를 소개해보세요",
            body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
            message: "이번 순서는 우리가 원하는 문제가 풀렸을때의 최상의 상태를 찾아보는 순서입니다. 최상의 상태를 찾고나면 왜 그렇게 될 수 없는지 원인을 고민할 수 있습니다. 자 이제 문제가 없는 최상의 상태를 각자 이야기 해볼까요?"
          })
        %{"kind" => "cause"} ->
          add_advice(state.id, %Advice{
            kind: "prompt_topic_guide",
            title: "이 순서를 소개해보세요",
            body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
            message: "이번 순서는 방금 토의한 최상의 상태를 막는 원인을 찾는 시간입니다. 정말로 최상의 상태를 방해하는 원인이 무엇일까요? 이걸 찾고나면 우리는 그 원인이 진짜인지 증거를 찾을 것입니다. 원인을 토의할때 바로 해결책을 찾지 않도록 조심해주시기 바랍니다 성급한 결정이 나올 수 있습니다. 자 이제 생각나는 원인을 이야기 해볼까요?"
          })
        %{"kind" => "cause_evidence"} ->
          add_advice(state.id, %Advice{
            kind: "prompt_topic_guide",
            title: "이 순서를 소개해보세요",
            body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
            message: "이번 순서는 방금 토의한 원인의 증거를 찾는 시간입니다. 증거가 확실해야 진짜 원인일 가능성이 있습니다. 증거가 잘 안나오면 다시 돌아가 새로운 원인을 찾아야할 수 도 있습니다. 자 이제 원인의 증거를 이야기 해볼까요?"
          })
        %{"kind" => "solution"} ->
          add_advice(state.id, %Advice{
            kind: "prompt_topic_guide",
            title: "이 순서를 소개해보세요",
            body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
            message: "이번 순서는 지금까지 논의한 원인에 대해 새로운 해결책을 토의하는 순서입니다. 해결책을 많이 도출하고 나면 그중 하나를 뽑고 해결책의 장/단점을 고민할 것입니다. 자 이제 해결책을 이야기 해볼까요?"
          })
        %{"kind" => "solution_pro"} ->
          add_advice(state.id, %Advice{
            kind: "prompt_topic_guide",
            title: "이 순서를 소개해보세요",
            body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
            message: "이번 순서는 우리가 제시할 해결책의 장점을 토론해보는 순서입니다. 단점을 미리 찾지 마시기 바랍니다. 장점을 최대한 부각할만한 것을 찾아봐야 합니다. 자 이제 해결책의 장점을 이야기 해볼까요?"
          })
        %{"kind" => "solution_con"} ->
          add_advice(state.id, %Advice{
            kind: "prompt_topic_guide",
            title: "이 순서를 소개해보세요",
            body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
            message: "이번 순서는 우리가 제시할 해결책의 단점을 토론해보는 순서입니다. 단점을 찾는 시간입니다. 최대한 객관적으로 단점을 고민하여 해결책이 타당한지 토의해봅시다. 자 이제 해결책의 단점을 이야기 해볼까요?"
          })
        %{"kind" => "solution_reason"} ->
          add_advice(state.id, %Advice{
            kind: "prompt_topic_guide",
            title: "이 순서를 소개해보세요",
            body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
            message: "이번 순서는 우리가 찾았던 다른 해결책 보다 왜 이것을 골라야 하는지 논리를 더 찾아보는 순서입니다. 좋은 당위성이 안나오면 다시 해결책을 토론해보거나 좋은 당위성이 나오면 우리가 해결책을 위한 행동을 토의할 것입니다. 자 이제 해결책의 독보적인 부분을 이야기 해볼까요?"
          })
        %{"kind" => "action_selection"} ->
          add_advice(state.id, %Advice{
            kind: "prompt_topic_guide",
            title: "이 순서를 소개해보세요",
            body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
            message: "이번 순서는 우리가 해결책을 위해 무엇을 할지 정해보는 시간입니다. 예를들면, '우리 구청에 청원을 보냅시다'와 같은 이야기를 해보는 순서입니다."
          })
        %{"kind" => "action_topic"} ->
          add_advice(state.id, %Advice{
            kind: "prompt_topic_guide",
            title: "이 순서를 소개해보세요",
            body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
            message: "이번 순서는 행동을 위해 우리가 결정해야할 것들을 토의해보는 순서입니다. 예를들면 어디에 '청원을 어디로 보낼지 정해야 합니다'와 같은 이야기를 나누면 됩니다."
          })
        _ ->
          add_advice(state.id, %Advice{
            kind: "prompt_topic_guide",
            title: "이 순서를 소개해보세요",
            body: "이 순서의 목적을 설명하면 참가자의 토론 참가가 편해집니다.",
            message: "이번 순서는 .. 입니다"
          })
      end

      if old_topics["current_topic_name"] != new_topics["current_topic_name"] do
        prev_topic = Topics.get_topic(new_topics, old_topics["current_topic_name"])
        message_new(state.id, "problem", "Bot", new_topics["current_topic_name"])
        topic_name = new_topics["current_topic_name"]
        page = case Discussion.Topics.get_topic(new_topics, topic_name) do
          nil -> 0
          x -> x["page"] || 0
        end
        Prompt.TimeManagementServer.postpond(state.prompt_time_management_server)

        # if new_topic["completed"] == false do
        #   if new_topic["voting"] == false && new_topic["kind"] == "cause" do
        #     message_new(state.id, "help_brainstorming2", "진행", topic_name)
        #   end

        #   case new_topic["kind"] do
        #     "problem_reading" ->
        #       add_an_answer_to_topic(state.id, topic_name, "네")
        #       start_voting_on_topic(state.id, topic_name)
        #     "cause-evidence-check" ->
        #       add_an_answer_to_topic(state.id, topic_name, "우리는 다양한 이해당사자를 생각하며 원인을 진행했다")
        #       add_an_answer_to_topic(state.id, topic_name, "우리는 다양한 원인을 찾아보았다")
        #       add_an_answer_to_topic(state.id, topic_name, "우리는 원인의 증거가 객관적인 자료에 근거한다")
        #       start_voting_on_topic(state.id, topic_name)
        #     "solution_check" ->
        #       add_an_answer_to_topic(state.id, topic_name, "네, 이제 해결책을 이야기 토론합시다")
        #       add_an_answer_to_topic(state.id, topic_name, "아니오, 우리 다시 원인부터 토론합시다")
        #       add_an_answer_to_topic(state.id, topic_name, "아니오, 우리 다시 해결책부터 토론합시다")
        #       start_voting_on_topic(state.id, topic_name)
        #     "action_selection" ->
        #       add_an_answer_to_topic(state.id, topic_name, "온라인 캠페인")
        #       add_an_answer_to_topic(state.id, topic_name, "청원 보내기")
        #       start_voting_on_topic(state.id, topic_name)
        #     "action_topic_selection" ->
        #       topic = Topics.get_topic_by_kind(new_topics, "action_selection")
        #       IO.inspect(topic)
        #       if topic != nil && Enum.at(topic["orders"], 0) == "온라인 캠페인" do
        #         add_an_answer_to_topic(state.id, topic_name, "캠페인 캐치프레이즈는 무엇으로 할까요?")
        #         add_an_answer_to_topic(state.id, topic_name, "온라인 어디에서 캠페인을 해야 할까요?")
        #         add_an_answer_to_topic(state.id, topic_name, "언제부터 몇일간 할까요?")
        #         message_new(state.id, "proto2_summary", "진행", topic_name)
        #       end
        #       if topic != nil && Enum.at(topic["orders"], 0) == "청원 보내기" do
        #         add_an_answer_to_topic(state.id, topic_name, "청원을 어디에 보내야 할까요?")
        #         add_an_answer_to_topic(state.id, topic_name, "청원 받을 분의 직함과 이름은 무엇인가요?")
        #         add_an_answer_to_topic(state.id, topic_name, "청원을 어떻게 보내야 할까요?")
        #         message_new(state.id, "proto2_summary", "진행", topic_name)
        #       end
        #     "action_plan_start" ->
        #       topic = Topics.get_topic_by_kind(new_topics, "action_topic_selection")
        #       add_topics(state.id, topic["orders"])
        #     _ -> nil
        #   end
        # end

        %{state|
          topic_page: page
        }
      else
        state
      end
    end
  end





  ## CALLS
  def handle_call({:login, user_entity}, _from, room_state) do
    reserved =
      if Enum.count(room_state.reserved) > 0 do
        [h | t] = room_state.reserved
        Process.cancel_timer(h)
        t
      else
        room_state.reserved
      end

    new_connections = if Map.get(room_state.connections, user_entity.id) == nil do
      Map.put(room_state.connections, user_entity.id, [1])
    else
      old = Map.get(room_state.connections, user_entity.id)
      Map.put(room_state.connections, user_entity.id, old ++ [1])
    end

    room_state = %{room_state|
      users: Map.put(room_state.users, user_entity.id, user_entity),
      reserved: reserved,
      connections: new_connections
    }

    Prompt.UserIdleServer.user_say(room_state.prompt_user_idle_server, user_entity.username)

    broadcast_state(room_state.id)
    {:reply, :ok, room_state}
  end

  def handle_call({:get_state}, _from, room_state) do
    {:reply, room_state, room_state}
  end

  def handle_call({:get_room_state}, _from, room_state) do
    {:reply, sanitize_room_state(room_state), room_state}
  end

  def handle_call({:problem_new, title}, _from, room_state) do
    IO.puts("handling cast :new_problem")

    reply =
      %{
        params: %{title: title, room_state: room_state},
        tasks: %{
          dup_check: :ready,
          db_input: :ready
        }
      }
      |> do_problem_new()

    reply
  end

  def handle_call({:entity_new, type, title, reference, force, username}, _from, room_state) do
    # Check the room Is Accepting The Entity Type
    entity_accept? =
      case is_room_accepting_type?(type, room_state) do
        true -> true
        false -> {:error, :entity_type_mismatch}
      end

    similar_response = fn
      [] ->
        :ok

      similar ->
        case force do
          true -> :ok
          _ -> {:error, :found_similar, similar}
        end
    end

    has_current_poll =
      case room_state.poll do
        nil -> {:error, :poll_is_null}
        poll -> {:ok, poll}
      end

    # Check the room has similar title for the entity type
    # DB Insert
    with true <- entity_accept?,
         list <- filter_room_entity_by_type(room_state, type, room_state.poll.entity_parent_id),
         similars <- filter_entity_list_by_similarity(list, title, 1),
         :ok <- similar_response.(similars),
         {:ok, poll} <- has_current_poll,
         {:ok, entity} <-
           Entity.Query.new(room_state.id, type, title, reference, poll.entity_parent_id) do
      # handle_call_response
      # TODO User 네임을 넣던가 할 수 있다
      # 채팅 메세지로 시각화
      entity_broadcast(room_state.id, entity.id)

      activity(room_state.id, "Added #{title}")

      {:reply, %{entity: entity},
       %{room_state | entities: Map.put(room_state.entities, entity.id, entity)}}
    else
      {:error, error} ->
        {:reply, %{error: error}, room_state}

      {:error, :found_similar, similar} ->
        {:reply, %{error: :found_similar, similars: similar}, room_state}
    end
  end

  def handle_call({:is_new_member_allowed?}, _from, room_state) do
    IO.puts("Room Reserve State")
    IO.inspect(Enum.count(room_state.users))
    IO.inspect(Enum.count(room_state.reserved))

    result =
      cond do
        Enum.count(room_state.users) + Enum.count(room_state.reserved) >=
            room_state.target_members ->
          false

        true ->
          true
      end


    new_state = if result == true do
      %{room_state|
        reserved: room_state.reserved ++ [Process.send_after(self(), :reserve_expired, 60_000)]
      }
    else
      room_state
    end

    {:reply, result, new_state}
  end

  def handle_call({:next_username}, _from, room_state) do
    next_name = "P" <> Integer.to_string(room_state.next_name_counter)
    new_room_state = %{room_state|
      next_name_counter: room_state.next_name_counter + 1
    }
    {:reply, next_name, new_room_state}
  end

  def handle_call({:previous_messages, room_id, from_id}, _from, room_state) do
    messages = Message.Query.previous_messages_from(room_id, from_id)
    {:reply, messages, room_state}
  end

  def handle_call({:get_poll}, _from, room_state) do
    {:reply, room_state.poll, room_state}
  end

  def handle_call({:room_level}, _from, room_state) do
    {:reply, room_state.room_level, room_state}
  end

  # Attributions

  # def chat_message_gen(x) do
  #   case x do
  #     "problem" -> "새 문제가 등록되었습니다"
  #     "cause" -> "새 원인이 등록되었습니다"
  #     "evidence" -> "새 증거가 등록되었습니다"
  #     "solution" -> "새 해결책이 등록되었습니다"
  #     "pro" -> "새 장점이 등록되었습니다"
  #     "con" -> "새 단점이 등록되었습니다"
  #     "people_name" -> "새 청원수신인이 등록되었습니다"
  #     "people_title" -> "새 청원수신인의 직함 등록되었습니다"
  #     "people_contact" -> "새 청원수신인의 연락/주소가 등록되었습니다"
  #     "campaign_title" -> "새 캠페인 문구가 등록되었습니다"
  #     "campaign_channel" -> "새 캠페인 채널이 등록되었습니다"
  #     "debate_closed" -> "새 토론 소감이 등록되었습니다"
  #   end
  # end

  defp is_room_accepting_type?(type, room_state) do
    room_state.poll.entity_type == type
  end

  defp filter_room_entity_by_type(room_state, type, parent_id \\ nil) do
    Enum.filter(room_state.entities, fn {_id, %{type: ex_type, parent_id: ex_parent_id}} ->
      ex_type == type && ex_parent_id == parent_id
    end)
  end

  def list_entity_by_parent(room_state, entity_type, parent_entity_id) do
    Enum.reduce(room_state.entities, [], fn {_, %{type: ex_type, parent_id: ex_parent_id}} = tup,
                                            acc ->
      if ex_type == entity_type && ex_parent_id == parent_entity_id do
        acc ++ [elem(tup, 1)]
      else
        acc
      end
    end)
  end

  defp filter_entity_list_by_similarity(list, title, similarity_ratio) do
    Enum.map(list, fn {_id, %{title: existing_title}} ->
      %{title: existing_title, score: Simetric.Jaro.Winkler.compare(existing_title, title)}
    end)
    |> Enum.filter(fn %{score: score} ->
      score >= similarity_ratio
    end)
    |> Enum.sort(fn e1, e2 -> e1[:score] > e2[:score] end)
    |> Enum.take(3)
  end

  defp do_problem_new(
         %{params: %{title: title, room_state: room_state}, tasks: %{db_input: :ready}} =
           task_sheet
       ) do
    IO.puts("Do1")

    Enum.filter(room_state.problems, fn {_, %{title: existing_title}} ->
      Simetric.Jaro.Winkler.compare(existing_title, title) >= 0.85
    end)
    |> Enum.map(fn {_, v} -> v.title end)
    |> case do
      [] ->
        do_problem_new(%{task_sheet | tasks: %{task_sheet.tasks | db_input: :done}})

      x ->
        {:reply, Envelop.Errors.add_error_msg(nil, "found_similarity", x), room_state}
    end
  end

  defp do_problem_new(%{
         params: %{title: title, room_state: room_state},
         tasks: %{dup_check: :ready}
       }) do
    IO.puts("Do2")
    local_id = "P" <> Integer.to_string(room_state.problem_seq)

    case Problem.Logic.make_problem_if_not_exist(room_state.id, local_id, title) do
      {:error, reason} ->
        case reason do
          {:already_exists} ->
            {:reply, Envelop.Errors.add_error_msg(nil, "already_exists"), room_state}

          _ ->
            {:reply, Envelop.Errors.add_error_msg(nil, "db_insert_fail"), room_state}
        end

      {:ok, %Problem{} = problem} ->
        room_state = %{
          room_state
          | problem_seq: room_state.problem_seq + 1,
            problems: Map.put(room_state.problems, problem.id, problem)
        }

        problem_broadcast_one(room_state.id, problem.id)

        message_new(
          room_state.id,
          "entity",
          "Bot",
          "새 후보가 등록 됨",
          message_link: %{
            problem: problem
          }
        )

        {:reply, %{problem: problem}, room_state}
    end
  end

  defp mod_state_for_vote_change([], state), do: state

  defp mod_state_for_vote_change([%{event: "deleted", vote: vote} | t], state) do
    mod_state_for_vote_change(t, %{state | votes: Map.delete(state.votes, vote.id)})
  end

  defp mod_state_for_vote_change([%{event: "inserted", vote: vote} | t], state) do
    mod_state_for_vote_change(t, %{state | votes: Map.put(state.votes, vote.id, vote)})
  end

  defp room_state_from_db(room_state) do
    case Room.Query.find_by_id(room_state.id) do
      nil ->
        room_state

      room_record ->
        room_state
        |> Map.put(:room_title, room_record.title)
        |> Map.put(:room_level, room_record.room_level)
        |> Map.put(:condition, room_record.condition)
        |> Map.put(:start_at, room_record.start_at)
        |> Map.put(:started, (room_record.started || false))
        |> Map.put(:redeem_code_waiting, room_record.redeem_code_waiting)
        |> Map.put(:redeem_code_done, room_record.redeem_code_done)
        |> Map.put(:topics, room_record.topics)
    end
  end

  defp start_timer_init(room_state) do
    if room_state.started == false do
      count = get_start_count(room_state)
      IO.puts "Set start timer after #{Integer.to_string(count)} seconds"
      if count > 0 do
        Process.send_after(self(), :waiting_due, count * 1000)
      end
    end

    room_state
  end

  defp sanitize_room_state(room_state) do
    %{
      room_title: room_state.room_title,
      room_level: room_state.room_level,
      condition: room_state.condition,
      poll: room_state.poll,
      polls: room_state.polls,
      accepting: room_state.accepting,
      polling: room_state.polling,
      problems: room_state.problems,
      problem_seq: room_state.problem_seq,
      entities: room_state.entities,
      entity_cursor: room_state.entity_cursor,
      votes: room_state.votes,
      users: room_state.users,
      tutorial_users: room_state.tutorial_users,
      target_members: room_state.target_members,
      start_count: get_start_count(room_state),
      started: room_state.started,
      reward_code: if get_start_count(room_state) <= 0 && room_state.started == false do
        room_state.redeem_code_waiting
      else
        ""
      end,
      previous_poll: room_state.previous_poll,
      in_tutorial: room_state.in_tutorial,
      topic_sentence: room_state.topic_sentence,
      commands: room_state.commands,
      promotes: room_state.promotes,
      goals: room_state.goals,
      vote_only: room_state.vote_only,
      vote_mode_votes: room_state.vote_mode_votes,
      vote_enabled: room_state.vote_enabled,
      topics: room_state.topics,
      topic_page: room_state.topic_page,
      moderatorTemplates: room_state.moderatorTemplates,
      moderator_id: room_state.moderator_id,
      advices: room_state.advises,
      enabled: room_state.enabled,
    }
  end

  defp get_start_count(room_state) do
    case room_state.start_at do
      nil -> 0
      start_at -> DateTime.diff(start_at, Timex.now())
    end
  end

  defp stat_channel_name(room_state) do
    "stat:" <> Integer.to_string(room_state.id)
  end

  defp stat_topic(room_state) do
    "stat:" <> Integer.to_string(room_state.id)
  end

  def entities_with(room_state, parent_id, kind) do
    Enum.filter(room_state.entities, fn({_, v}) ->
      (v.parent_id == parent_id) && (v.type == kind)
    end)
    |> Enum.map( fn({_, v}) -> v end )
  end

  def room_state_add_bot(room_state) do
    bot_pid = NGOBot.start_link(room_state.id)
    %{room_state|
      bot_pid: bot_pid
    }
  end

  def put_current_poll_to_previous_poll(%{poll: poll} = room_state) do
    if poll == nil do
      room_state
    else
      %{room_state|
        previous_poll: poll
      }
    end
  end

  def broadcast_messages(room_state, messages) do
    MicrongoPhxWeb.Endpoint.broadcast(stat_channel_name(room_state), "message", %{
      messages: messages
    })
  end

end
