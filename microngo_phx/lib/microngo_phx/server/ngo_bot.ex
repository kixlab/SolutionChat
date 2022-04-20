defmodule NGOBot.Message do
  defstruct speaker: nil, message: nil, intent: nil
end

defmodule NGOBot do
  use GenStateMachine

  defstruct topic: "",
            msg_buffer: [],
            msg_buffer_capacity: 20,
            topic_target_count: 4,
            topics: [],
            votes: %{},
            members: 4,
            focus: nil,
            artifact: %{},
            room_id: nil,
            intent_ratio: 0,
            topic_decreasing_count: 0,
            topic_intro: []

  def start_link(room_id) do
    {:ok, pid} = GenStateMachine.start_link(NGOBot, {:waiting_for_greeting,  %NGOBot{room_id: room_id}})
    GenStateMachine.cast(pid, {:after_init})
    pid
  end

  def talk(pid, message) do
    GenStateMachine.call(pid, {:talk, message})
  end

  def change_stage(pid, stage) do
    GenStateMachine.cast(pid, {:change_stage, stage})
  end

  def handle_event(:cast, {:after_init}, _, data) do
    next_state = :handle_discussion
    {:next_state, next_state, data}
  end

  # def handle_event(:cast, {:talk, _}, :waiting_for_greeting, data) do
  #   spawn(NGOBot, :do_introduce_gently, [data])
  #   new_data = data
  #   |> clear_msg_buffer()
  #   {:next_state, :handle_for_greeting, new_data}
  # end

  # def handle_event(:cast, {:talk, message}, :handle_for_greeting, data) do
  #   n = NLU.query(message)

  #   new_data = data
  #   |> add_buffer_message(%NGOBot.Message{
  #     speaker: nil,
  #     message: message,
  #     intent: NLU.Result.intent_name(n)
  #   })

  #   new_intent_ratio = calc_intent_ratio(new_data.msg_buffer, "chat-ice-braking") +
  #     calc_intent_ratio(new_data.msg_buffer, "d-disclosure") +
  #     calc_intent_ratio(new_data.msg_buffer, "q-question")

  #   new_data = cond do
  #     new_data.intent_ratio < new_intent_ratio ->
  #       new_data
  #       |> intent_ratio(new_intent_ratio)
  #     new_data.intent_ratio > new_intent_ratio ->
  #       new_data
  #       |> intent_ratio(new_intent_ratio)
  #       |> topic_decreasing_count(topic_decreasing_count(data) + 1)
  #     true -> new_data
  #   end

  #   IO.inspect new_intent_ratio
  #   IO.inspect topic_decreasing_count(new_data)
  #   #if topic_decreasing_count(new_data) >= 7 do

  #   if new_intent_ratio < 0.5 && Enum.count(new_data.msg_buffer) > 10   do
  #     # Topic 바꾸기
  #     change_stage(self(), :start_discussion)
  #   end

  #   {:next_state, :handle_for_greeting, new_data}
  # end

  # def handle_event(:cast, {:change_stage, :start_discussion}, _, data) do
  #   new_data = data
  #   |> clear_msg_buffer()
  #   spawn(NGOBot, :do_start_discussion, [new_data, self()])
  #   {:next_state, :start_discussion, new_data}
  # end

  # def handle_event(:cast, {:talk, message}, :start_discussion, data) do
  #   n = NLU.query(message)
  #   new_data = data
  #   |> add_buffer_message(%NGOBot.Message{
  #     speaker: nil,
  #     message: message,
  #     intent: NLU.Result.intent_name(n)
  #   })
  #   {:next_state, :start_discussion, new_data}
  # end

  # def handle_event(:cast, {:change_stage, topic}, state, data) do
  #   IO.inspect topic

  #   case topic do
  #     %{"kind" => "objective"} ->
  #       Room.Server.add_advice(data.room_id, %Advice{
  #         kind: "topic_guide", title: "이 순서를 소개해보세요", body: "해당 문제의 최선의 상태를 생각해보고 차후에는 최선의 상태와 현실과의 차이를 점검할 것입니다", message: "이번 순서는 현재 문제가 풀렸을때의 최상의 상태를 찾아보는 순서입니다. 최상의 상태를 찾은 뒤 현재 상태를 점검하고 왜 해당 문제가 발생하는지. 이렇게 생각해보면서 토론을 진행했으면 좋겠습니다"
  #       })
  #       true
  #     _ -> nil
  #   end
  #   {:next_state, state, data}
  # end

  # def handle_event(:cast, {:talk, message}, :new_problem, data) do
  #   n = NLU.query(message)
  #   new_data = data
  #   |> add_buffer_message(%NGOBot.Message{
  #     speaker: nil,
  #     message: message,
  #     intent: NLU.Result.intent_name(n)
  #   })
  #   {:next_state, :new_problem, new_data}
  # end

  # def handle_event(:cast, {:change_stage, :handle_discussion}, _, data) do
  #   {:next_state, :handle_discussion, data}
  # end

  def handle_event({:cast, from}, {:talk, message}, :handle_discussion, data) do
    # n = NLU.query(message)
    new_data = data
    |> add_buffer_message(%NGOBot.Message{
      speaker: nil,
      message: message,
      intent: ""
    })

    topic_message = if Enum.count(new_data.msg_buffer) > 10 do
      msg = elem(topic_from_dialogs(new_data.msg_buffer), 0)
      msg.message
    else
      ""
    end

    new_data = if topic_message != new_data.topic do
      say_recommendation(topic_message, data)
      %{new_data|
        topic: topic_message
      }
    else
      new_data
    end

    #new_data = do_react_for_intent(new_data, n)

    case Enum.take(score_list(new_data.msg_buffer), -1) do
      [] ->  {:next_state, :handle_discussion, new_data, [{:reply, from, {Enum.count(new_data.msg_buffer), 0}}]}
      [b] -> {:next_state, :handle_discussion, new_data, [{:reply, from, {Enum.count(new_data.msg_buffer), b}}]}
      _ -> {:next_state, :handle_discussion, new_data, [{:reply, from, {Enum.count(new_data.msg_buffer), 0}}]}
    end

    # {:next_state, :handle_discussion, new_data}
  end

  # def handle_event(:cast, {:talk, message}, :topic_watch1, data) do
  #   IO.puts "talk: #{message} | #{data.topic}"

  #   msg_buffer = data.msg_buffer ++ [message]
  #   msg_buffer = if (Enum.count(msg_buffer) >  data.msg_buffer_capacity) do
  #     List.delete_at(msg_buffer, 0)
  #   else
  #     msg_buffer
  #   end

  #   chopped_messages = Enum.map(msg_buffer, fn (msg) -> N.gram(msg, 4) |> Enum.uniq() end)
  #   score_map = List.foldl(chopped_messages, FreqDict.new(), fn (elem, dict) ->
  #     List.foldl(elem, dict, fn (e, dic) ->
  #       FreqDict.add(dic, e)
  #     end)
  #   end)
  #   score_list = Enum.map(chopped_messages, fn(x) ->
  #     List.foldl(x, 0, fn (token, score) ->
  #       score + FreqDict.count(score_map, token)
  #     end)
  #   end)

  #   IO.inspect score_list

  #   top_message = Enum.zip(msg_buffer, score_list) #{msg, 00}
  #   |> List.foldl(nil, fn(current, acc) ->
  #     case acc do
  #       nil -> current
  #       x ->
  #         if elem(x, 1) < elem(current, 1) do
  #           current
  #         else
  #           x
  #         end
  #     end
  #   end)


  #   current_topic_text = elem(top_message, 0)
  #   new_topics = if Enum.count(msg_buffer) >= 5 do
  #     data.topics ++ [current_topic_text]
  #     |> Enum.dedup()
  #   else
  #     data.topics
  #   end

  #   IO.puts current_topic_text

  #   if Enum.count(new_topics) > Enum.count(data.topics) do #if Enum.count(new_topics) >= data.topic_target_count do
  #     say_recommendation(current_topic_text, data)
  #     {:next_state, :topic_watch, %{data|
  #       msg_buffer: msg_buffer,
  #       topic: current_topic_text,
  #       topics: new_topics}
  #     }
  #   else
  #     {:next_state, :topic_watch, %{data|
  #       msg_buffer: msg_buffer,
  #       topic: current_topic_text,
  #       topics: new_topics}
  #     }
  #   end
  # end

  # def handle_event(:cast, {:talk, message}, :category_vote, data) do
  #   intent = case message do
  #     "원인" -> :cause
  #     "해결책" -> :solution
  #     "없음" -> :no_topic
  #     _ -> :no_intent
  #   end

  #   new_data = data
  #   |> apply_vote(intent)

  #   consensus =
  #     if Enum.count(new_data.votes) == 0 do
  #       nil
  #     else
  #       top_vote = Enum.reduce(new_data.votes, nil, fn
  #         (x, nil) -> x
  #         ({cur_title, cur_score}, {acc_title, acc_score}) ->
  #           if cur_score > acc_score do
  #             {cur_title, cur_score}
  #           else
  #             {acc_title, acc_score}
  #           end
  #       end)

  #       cond do
  #         top_vote == nil -> nil
  #         elem(top_vote, 1) >= 3 -> top_vote
  #         true -> nil
  #       end
  #     end

  #   if consensus == nil do
  #     {:next_state, :category_vote, new_data}
  #   else
  #     case elem(consensus, 0) do
  #       :no_topic ->
  #         say("아직 토론에 중요한 진전이 없었군요. 좀 더 토론해봅시다!", data)
  #         new_data = new_data
  #         |> msg_clear()
  #         {:next_state, :topic_watch, new_data}
  #       :cause ->
  #         say("원인을 찾았군요! 의견을 수렴하기위해 각자가 생각하는 원인을 채팅에 적어봅시다!", data)
  #         new_data = new_data
  #         |> msg_clear()
  #         |> put_focus(:cause)
  #         {:next_state, :entity_building, new_data}
  #       :solution ->
  #         say("해결책을 찾았군요! 의견을 수렴하기위해 각자가 생각하는 해결책을 채팅에 적어봅시다!", data)
  #         new_data = new_data
  #         |> msg_clear()
  #         |> put_focus(:solution)
  #         {:next_state, :entity_building, new_data}
  #     end
  #   end
  # end

  # def handle_event(:cast, {:talk, message}, :entity_building, data) do
  #   new_data =
  #     data
  #     |> add_buffer_message(message)

  #   if Enum.count(new_data.msg_buffer) <= 4 do
  #     say("더 의견 주세요", data)
  #     {:next_state, :entity_building, new_data}
  #   else
  #     {topic, _} = topic_from_dialogs(new_data.msg_buffer)
  #     say("의견 감사합니다.", data)
  #     say("대부분 의견이 아래의 내용으로 모이는것 같네요", data)
  #     say("토픽: #{topic}", data)
  #     say("이것을 #{Atom.to_string(data.focus)}에 기록하겠습니다", data)
  #     new_data =
  #       new_data
  #       |> put_artifact(data.focus, topic)
  #       |> msg_clear()
  #     say_agenda("#{Atom.to_string(data.focus)}: #{topic}", data)
  #     say("이제 또 토의해봅시다", data)
  #     {:next_state, :topic_watch, new_data}
  #   end
  # end

  def handle_event(arg1, arg2, state, data) do
    IO.puts "Unknown"
    IO.inspect arg1
    IO.inspect arg2
    {:next_state, state, data}
  end

  ##Attributions - data
  def apply_vote(data, intent) do
    new_votes = if intent == :no_intent do
      data.votes
    else
      Map.get_and_update(data.votes, intent, fn
        nil -> {nil, 1}
        x -> {x, x+1}
      end)
      |> elem(1)
    end

    %{data | votes: new_votes}
  end

  def msg_clear(data) do
    %{data|
      topic: "",
      msg_buffer: [],
      topics: [],
      votes: %{},
    }
  end

  def put_focus(data, focusing) do
    %{data|
      focus: focusing
    }
  end

  def add_buffer_message(data, message) do
    msg_buffer = data.msg_buffer ++ [message]
    msg_buffer = if (Enum.count(msg_buffer) >  data.msg_buffer_capacity) do
      List.delete_at(msg_buffer, 0)
    else
      msg_buffer
    end
    %{data|
      msg_buffer: msg_buffer
    }
  end

  def put_artifact(data, key, value) do
    %{data|
      artifact: Map.put(data.artifact, key, value)
    }
  end


  ## attributions list
  @spec topic_from_dialogs(list(%NGOBot.Message{})) :: {%NGOBot.Message{}, number}
  def topic_from_dialogs(dialogs) do
    gram = 4
    chopped_messages = Enum.map(dialogs, fn (msg) -> N.gram(msg.message, gram) |> Enum.uniq() end)
    score_map = List.foldl(chopped_messages, FreqDict.new(), fn (elem, dict) ->
      List.foldl(elem, dict, fn (e, dic) ->
        FreqDict.add(dic, e)
      end)
    end)
    score_list = Enum.map(chopped_messages, fn(x) ->
      List.foldl(x, 0, fn (token, score) ->
        score + FreqDict.count(score_map, token)
      end)
    end)

    IO.inspect score_list

    top_message = Enum.zip(dialogs, score_list) #{msg, 00}
    |> List.foldl(nil, fn(current, acc) ->
      case acc do
        nil -> current
        x ->
          if elem(x, 1) < elem(current, 1) do
            current
          else
            x
          end
      end
    end)

    top_message
  end

  def score_list(dialogs) do
    gram = 4
    chopped_messages = Enum.map(dialogs, fn (msg) -> N.gram(msg.message, gram) |> Enum.uniq() end)
    score_map = List.foldl(chopped_messages, FreqDict.new(), fn (elem, dict) ->
      List.foldl(elem, dict, fn (e, dic) ->
        FreqDict.add(dic, e)
      end)
    end)
    score_list = Enum.map(chopped_messages, fn(x) ->
      List.foldl(x, 0, fn (token, score) ->
        score + FreqDict.count(score_map, token)
      end)
    end)

    score_list
  end

  def say_manual(message, type, data, wait \\ 0) do
    IO.puts "say: #{message}"
    if data.room_id != nil do
      Room.Server.message_new(data.room_id, type, "Bot", message)
      if wait >  0 do
        :timer.sleep(wait);
      end
    else
      IO.puts message
    end
  end

  def say(message, data, wait \\ 0) do
    IO.puts "say: #{message}"
    if data.room_id != nil do
      Room.Server.message_new(data.room_id, "normal", "Bot", message)
      if wait >  0 do
        :timer.sleep(wait);
      end
    else
      IO.puts message
    end
  end

  def say_recommendation(message, data) do
    IO.puts "rec: #{message}"
    if data.room_id != nil do
      Room.Server.set_topic_sentence(data.room_id, message)
    else
      IO.puts message
    end
  end

  def say_special(message, kind, data) do
    IO.puts "#{kind}: #{message}"
    if data.room_id != nil do
      Room.Server.message_new(data.room_id, kind, "Bot", message)
    else
      IO.puts message
    end
  end


  def say_problem(message, data) do
    IO.puts "problem: #{message}"
    if data.room_id != nil do
      Room.Server.message_new(data.room_id, "problem", "Bot", message)
    else
      IO.puts message
    end
  end


  def say_agenda(message, data) do
    IO.puts "agenda: #{message}"
    if data.room_id != nil do
      Room.Server.message_new(data.room_id, "green", "Bot", message)
    else
      IO.puts message
    end
  end

  def do_introduce(data) do
    room_state = Room.Server.get_state(data.room_id)
    delay = 3000
    say("안녕하세요 저는 마이크로 NGO 봇입니다.", data, delay)
    say("우리는 이제 아래의 문제에 대해 토론 할 것입니다", data, delay)
    say_problem("#{room_state.room_title}", data)
    say("위의 문제를 읽어보세요.", data, delay)
    say("이제 여러분께 질문이 있습니다.", data, delay)
    Room.Server.force_next(data.room_id)
    poll = Room.Server.get_poll(data.room_id)
    Room.Server.message_new(data.room_id, "agenda", "Bot", poll.title)
    Room.Server.entity_new(data.room_id, "problem", "네, 문제를 읽었습니다.", "Bot", true, "Bot")
    say_manual("우리는 다음과 같은 선택이 있습니다", "entity", data)
    say("만일 읽으셨다면 위의 투표 버튼을 눌러주세요", data, delay)
    # say_special("how_to_vote", "how_to_vote", data)
    say("다수가 문제를 읽었다고 투표해주면 다음 과정을 안내하겠습니다", data, delay)
  end

  def do_introduce_gently(data) do
    delay = 3000
    say("제가 시작해도 될까요?", data, delay)
    do_introduce(data)
  end

  def do_start_discussion(data, bot_pid) do
    delay = 3000
    say("Let's start a discussion now.", data, delay)
    say("The problem we are about to discuss now is", data, delay)
    say("The American public school diet is usually unbalanced in nutrition", data, delay)
    say("I prepared some questions to solve this problem.", data, delay)
    say("We will answer these questions and solve the problem.", data, delay)
    say("We will first answer questions to analyze the problem", data, delay)
    say("We will then plan our online campaign or petition.", data, delay)
    say("So let me start with the first question.", data, delay)
    NGOBot.change_stage(bot_pid, :new_problem)
  end

  def do_new_problem(data, bot_pid) do
    poll = Room.Server.get_poll(data.room_id)
    if poll.entity_type == "debate_closed" do
      NGOBot.change_stage(bot_pid, :handle_discussion)
    else
      delay = 3000;
      say("이제 제가 드릴 질문은", data, delay)
      Room.Server.message_new(data.room_id, "agenda", "Bot", poll.title)

      if poll.entity_type == "route" || poll.entity_type == "action_type" do
        say_manual("자 이제 우리에게 다음과 같은 선택이 있습니다", "entity", data)
        say("이제 투표 합시다", data, delay)
      else
        say("이 질문을 위한 브레인스토밍 시간입니다!", data, delay)
        say_special("help_brainstorming", "help_brainstorming", data)
        say("전 투표시간에 돌아오겠습니다 (투표때가 되면 왼쪽패널에 투표합시다 버튼을 누르세요))!", data, delay)
      end
      NGOBot.change_stage(bot_pid, :handle_discussion)
    end
  end

  def do_react_for_intent(data, result) do
    should_react = String.contains?(result.input, "@bot") or NLU.Result.probability(result) > 0.4
    if should_react == false do
      data
    else
      case NLU.Result.intent_name(result) do
        "none" ->
          data
        "q-proceed" ->
          say("We are doing discuss and vote process", data)
          say("If more than 51% of the participants support any candidate,", data)
          say("We will proceed to the next question", data)
          say_manual("We have following candidates", "entity", data)
          data
        "q-topic" ->
          poll = Room.Server.get_poll(data.room_id)
          say("The question we answering now is", data)
          say("#{poll.title}", data)
          data
        "troll" ->
          say("I sense some troll here.. or my error..", data)
          data
        "q-add-candidate" ->
          say("How to add? Click the message that you want to add", data)
          data
        _ -> data
      end
    end
  end

  def clear_msg_buffer(data) do
    %NGOBot{data|
      msg_buffer: []
    }
  end

  def add_msg_buffer(data, message) do
    msg_buffer = data.msg_buffer ++ [message]
    msg_buffer = if (Enum.count(msg_buffer) >  data.msg_buffer_capacity) do
      List.delete_at(msg_buffer, 0)
    else
      msg_buffer
    end

    %NGOBot{data|
      msg_buffer: msg_buffer
    }
  end

  def topic_decreasing_count(data) do
    data.topic_decreasing_count
  end
  def topic_decreasing_count(data, new_value) do
   %NGOBot{data|
      topic_decreasing_count: new_value
    }
  end

  def intent_ratio(data, new_value) do
    %NGOBot{data|
      intent_ratio: new_value
    }
  end

  def calc_intent_ratio(msg_buffer, intent) do
    length = Enum.count(msg_buffer)
    target = Enum.filter(msg_buffer, fn(x) -> x.intent == intent end)
    |> Enum.count()

    if length == 0 do
      0
    else
      target / length
    end
  end

end
