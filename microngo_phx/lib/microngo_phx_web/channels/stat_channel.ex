defmodule Chatroom.StatChannel do
  alias MicrongoPhx.Repo
  use Phoenix.Channel

  def join("stat:" <> roomID, _payload, socket) do
    IO.puts("joined: " <> roomID)
    {roomID_num, _} = Integer.parse(roomID)
    Room.Supervisor.start_room(roomID_num)
    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    do_push_room_state(socket)
    {:noreply, socket}
  end

  ##소켓에서 짧은 유저아이디를 받고 가입할 수 있게 해보자
  def handle_in("sign_up", _msg, socket) do
    username = Room.Server.next_username(get_roomID_from_socket(socket))
    {:ok, user} =
      User.Logic.signup(%{
        "email" => username,
        "password" => username,
        "username" => username
      })
    token = Phoenix.Token.sign(socket, "user socket", user.id)
    {:reply, {:ok, %{token: token}}, socket}
  end

  def handle_in("login", %{"token" => token}, socket) do
    case Phoenix.Token.verify(socket, "user socket", token) do
      {:ok, user_id} ->
        case Repo.get(User, user_id) do
          nil ->
            {:reply, {:error, %{result: false, reason: "no such user exists"}}, socket}

          %User{} = user ->
            case Room.Server.login(get_roomID_from_socket(socket), user) do
              :ok ->
                socket =
                  socket
                  |> assign(:user_id, user_id)
                  |> assign(:user, user)

                caller_pid = self()

                spawn(fn ->
                  Process.monitor(caller_pid)
                  receive do
                    {:DOWN, _ref, :process, _pid, _reason} ->
                      Room.Server.disconnecting(get_roomID_from_socket(socket), user.id)
                      IO.puts("CONNECTION DISCONNECTED FROM USER #{Integer.to_string(user.id)}")
                  end
                end)

                {:reply, {:ok, %{result: true, user_id: user_id, username: user.username }}, socket}
              {:error, reason} ->
                {:reply, {:error, %{result: false, reason: reason}}, socket}
            end
        end

      {:error, reason} ->
        {:reply, {:error, %{result: false, reason: reason}}, socket}
    end
  end
  def handle_in("login", _params, socket) do
    {:reply, {:error, "not enough params"}, socket}
  end

  def handle_in("tutorial_done", _params, %{assigns: %{user_id: user_id}} = socket) do
    Room.Server.tutorial_done(get_roomID_from_socket(socket), user_id)
    {:reply, {:ok, %{}}, socket}
  end
  def handle_in("tutorial_done", _params, socket) do
    {:reply, {:ok, %{}}, socket}
  end

  def handle_in(
        "entity_new",
        %{
          "type" => type,
          "title" => title,
          "reference" => reference,
          "force" => force
        },
        %{assigns: %{user: user}} = socket
      ) do
    reply =
      Room.Server.entity_new(
        get_roomID_from_socket(socket),
        type,
        title,
        reference,
        force,
        user.username
      )

    {:reply, {:ok, reply}, socket}
  end

  def handle_in("problem_new", payload, socket) do
    reply =
      Room.Server.problem_new(
        get_roomID_from_socket(socket),
        payload["title"]
      )

    case reply do
      %{problem: problem} ->
        {:reply, {:ok, %{problem: problem}}, socket}

      %{errors: errors} ->
        {:reply, {:ok, %{errors: errors}}, socket}
    end
  end

  def handle_in("message_new", payload, %{assigns: %{user_id: user_id, user: user}} = socket) do
    Room.Server.message_new(
      get_roomID_from_socket(socket),
      "normal",
      user.username,
      payload["text"],
      user_id: user_id,
      parent: payload["parent"]
    )

    {:noreply, socket}
  end

  def handle_in("message_new", _payload, socket) do
    {:reply, {:error, %{reason: "login_required"}}, socket}
  end

  def handle_in(
        "vote",
        %{
          "poll_id" => poll_id,
          "entity_id" => entity_id,
          "value" => value
        },
        %{assigns: %{user_id: user_id}} = socket
      ) do
    Room.Server.poll_vote(
      get_roomID_from_socket(socket),
      poll_id,
      entity_id,
      user_id,
      value
    )

    {:noreply, socket}
  end

  def handle_in("get_room_state", _payload, socket) do
    do_push_room_state(socket)
    {:noreply, socket}
  end

  def handle_in("get_previous_messages", payload, socket) do
    #이전 메세지 불러오기
    from_id = Map.get(payload, "from_id", nil)

    messages = Room.Server.previous_messages(
      get_roomID_from_socket(socket),
      from_id
    )

    if Enum.count(messages) > 0 do
      push(
        socket,
        "message",
        %{
          messages: messages
        }
      )
    end
    {:noreply, socket}
  end

  def handle_in("promote", %{"message" => message}, %{assigns: %{user: user}} = socket) do
    Room.Server.promote(
      get_roomID_from_socket(socket),
      message,
      user.username
    )
    {:noreply, socket}
  end

  def handle_in("vote_mode_vote", %{"value" => value}, %{assigns: %{user: user}} = socket) do
    Room.Server.vote_mode_vote(
      get_roomID_from_socket(socket),
      user.username,
      value
    )
    {:noreply, socket}
  end

  def handle_in("new_topic_above", %{
    "from_name" => from_name,
    "topic_name" => new_topic_name
  }, socket) do
    Room.Server.new_topic_above(
      get_roomID_from_socket(socket), from_name, new_topic_name)
    {:noreply, socket}
  end

  def handle_in("new_topic_below", %{
    "from_name" => from_name,
    "topic_name" => new_topic_name
  }, socket) do
    Room.Server.new_topic_below(
      get_roomID_from_socket(socket), from_name, new_topic_name)
    {:noreply, socket}
  end

  def handle_in("add_an_answer_to_topic", %{
    "topic_name" => topic_name,
    "answer_name" => answer_name
  }, socket) do
    Room.Server.add_an_answer_to_topic(get_roomID_from_socket(socket), topic_name, answer_name)
    {:noreply, socket}
  end

  #start_voting_on_topic(room_id, topic_name)
  def handle_in("start_voting_on_topic", %{
    "topic_name" => topic_name
  }, socket) do
    Room.Server.start_voting_on_topic(get_roomID_from_socket(socket), topic_name)
    {:noreply, socket}
  end

  def handle_in("vote_on_answer", %{
    "topic_name" => topic_name,
    "answer_name" => answer_name,
    "up" => up
  }, %{assigns: %{user: user}} = socket) do
    #room_id, topic_name, answer_name, user_name, up
    Room.Server.vote_on_answer(get_roomID_from_socket(socket), topic_name, answer_name, user.username, up)
    {:noreply, socket}
  end
  def handle_in("vote_on_answer", _params, socket) do # catch all
    {:noreply, socket}
  end

  def handle_in("mark_as_done", %{
    "topic_name" => topic_name
  }, socket) do
    Room.Server.mark_as_done(get_roomID_from_socket(socket), topic_name)
    {:noreply, socket}
  end

  def handle_in("reopen", %{
    "topic_name" => topic_name
  }, socket) do
    Room.Server.reopen(get_roomID_from_socket(socket), topic_name)
    {:noreply, socket}
  end

  def handle_in("focus", %{
    "topic_name" => topic_name
  }, socket) do
    Room.Server.focus(get_roomID_from_socket(socket), topic_name)
    {:noreply, socket}
  end

  def handle_in("delete_answer", %{
    "topic_name" => topic_name,
    "answer_name" => answer_name
  }, socket) do
    Room.Server.delete_answer(get_roomID_from_socket(socket), topic_name, answer_name)
    {:noreply, socket}
  end

  def handle_in("finish_discussion", _params, socket) do
    Room.Server.message_new(get_roomID_from_socket(socket), "reward", "진행", "사후 설문 작성해주세요")
    {:noreply, socket}
  end

  def handle_in("typing", _params, %{assigns: %{user: user}} = socket) do
    broadcast! socket, "typing", %{username: user.username}
    {:noreply, socket}
  end
  def handle_in("typing", _params, socket) do
    {:noreply, socket}
  end

  def handle_in("start", _params, socket) do
    Room.Server.start(get_roomID_from_socket(socket))
    {:noreply, socket}
  end

  def handle_in("designate_moderator", %{"user_id" => user_id}, socket) do
    Room.Server.designate_moderator(get_roomID_from_socket(socket), user_id)
    {:noreply, socket}
  end

  def handle_in("enabled", %{"enabled" => enabled}, socket) do
    Room.Server.enabled(get_roomID_from_socket(socket), enabled)
    {:noreply, socket}
  end

  def handle_in("log", %{"text" => text}, %{assigns: %{user: user}}=socket) do
    Room.Server.log(
      get_roomID_from_socket(socket),
      "#{user.username}: " <> text
    )
    {:noreply, socket}
  end
  def handle_in("log", %{"text" => text}, socket) do
    Room.Server.log(
      get_roomID_from_socket(socket),
      text
    )
    {:noreply, socket}
  end

  ##

  defp do_push_room_state(socket) do
    push(socket, "get_room_state", Room.Server.get_room_state(get_roomID_from_socket(socket)))
  end

  defp get_roomID_from_socket(socket) do
    "stat:" <> roomID = socket.topic
    {roomID_num, _} = Integer.parse(roomID)
    roomID_num
  end
end
