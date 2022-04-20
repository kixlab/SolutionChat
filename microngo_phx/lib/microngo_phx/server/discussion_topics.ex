defmodule Discussion.Topics do
  alias Discussion.Topics
  alias Discussion.Topic

  defstruct data: %{}, orders: []

  @spec new() :: %{}
  def new() do
    %{
      "data" => %{},
      "orders" => [],
      "current_topic_name" => ""
    }
  end

  @spec new_topic(%{}, String.t()) :: %{}
  def new_topic(topics, topic_name, opt \\ []) do
    if Map.has_key?(topics["data"], topic_name) do
      topics
    else
      payload = Topic.new(topic_name, opt)
      %{topics|
        "data" => Map.put(topics["data"], topic_name, payload),
        "orders" => topics["orders"] ++ [topic_name],
        "current_topic_name" => topic_name
      }
    end
  end

  def new_topic_below(topics, from_name, topic_name) do
    if Map.has_key?(topics["data"], from_name) == false do
      topics
    else
      from_index = Enum.find_index(topics["orders"], fn(x) ->
        x == from_name
      end)

      from_topic = Map.get(topics["data"], from_name)
      new_orders = List.insert_at(topics["orders"], from_index + 1, topic_name)
      new_topic = Topic.new(topic_name, page: from_topic["page"])

      %{topics|
        "data" => Map.put(topics["data"], topic_name, new_topic),
        "orders" => new_orders,
        "current_topic_name" => topic_name
      }
    end
  end

  def new_topic_above(topics, from_name, topic_name) do
    if Map.has_key?(topics["data"], from_name) == false do
      topics
    else
      from_index = Enum.find_index(topics["orders"], fn(x) ->
        x == from_name
      end)
      from_topic = Map.get(topics["data"], from_name)
      new_orders = List.insert_at(topics["orders"], from_index, topic_name)
      new_topic = Topic.new(topic_name, page: from_topic["page"])

      %{topics|
        "data" => Map.put(topics["data"], topic_name, new_topic),
        "orders" => new_orders,
        "current_topic_name" => topic_name
      }
    end
  end

  def get_topic(topics, topic_name) do
    Map.get(topics["data"], topic_name)
  end

  def get_topic_by_kind(topics, kind) do
    matched_name = Enum.find(topics["orders"], fn(topic_name) ->
      topic = Map.get(topics["data"], topic_name)
      topic["kind"] == kind
    end)
    Map.get(topics["data"], matched_name)
  end

  def add_an_answer_to_topic(topics, topic_name, answer_name) do
    if Map.has_key?(topics["data"], topic_name) == false do
      topics
    else
      %{topics|
        "data" => Map.put(
          topics["data"],
          topic_name,
          Topic.add_answer(get_topic(topics, topic_name), answer_name)
        )
      }
    end
  end

  def start_voting_on_topic(topics, topic_name) do
    if Map.has_key?(topics["data"], topic_name) == false do
      topics
    else
      %{topics|
        "data" => Map.put(
          topics["data"],
          topic_name,
          Topic.start_voting(get_topic(topics, topic_name))
        )
      }
    end
  end

  def vote_on_answer(topics, topic_name, answer_name, user_name, up) do
    if Map.has_key?(topics["data"], topic_name) == false do
      topics
    else
      %{topics|
        "data" => Map.put(
          topics["data"],
          topic_name,
          Topic.vote_on_answer(get_topic(topics, topic_name), answer_name, user_name, up)
        )
      }
    end
  end

  def mark_as_done(topics, topic_name) do
    if Map.has_key?(topics["data"], topic_name) == false do
      topics
    else
      idx = Enum.find_index(topics["orders"], fn(x) -> x == topic_name end)
      next_topic_name = if idx == nil do
        nil
      else
        Enum.drop(topics["orders"], idx + 1)
        |> Enum.find(fn(x) ->
          get_topic(topics, x)["completed"] == false
        end)
      end

      %{topics|
        "data" => Map.put(
          topics["data"],
          topic_name,
          Topic.mark_as_done(get_topic(topics, topic_name))
        ),
        "current_topic_name" => next_topic_name
      }
    end
  end

  def reopen(topics, topic_name) do
    if Map.has_key?(topics["data"], topic_name) == false do
      topics
    else
      %{topics|
        "data" => Map.put(
          topics["data"],
          topic_name,
          Topic.reopen(get_topic(topics, topic_name))
        )
      }
    end
  end

  def focus(topics, topic_name) do
    if topic_name == nil || topic_name == "" do
      %{topics|
        "current_topic_name" => ""
      }
    else
      if Map.has_key?(topics["data"], topic_name) == false do
        topics
      else
        %{topics|
          "current_topic_name" => topic_name,
          "data" => Map.put(
            topics["data"],
            topic_name,
            Topic.reopen(get_topic(topics, topic_name))
          )
        }
      end
    end
  end

  def delete_answer(topics, topic_name, answer_name) do
    if Map.has_key?(topics["data"], topic_name) == false do
      topics
    else
      %{topics|
        "data" => Map.put(
          topics["data"],
          topic_name,
          Topic.delete_answer(get_topic(topics, topic_name), answer_name)
        )
      }
    end
  end

  def current_topic_name(topics) do
    topics["current_topic_name"]
  end

  def current_topic(topics) do
    get_topic(topics, topics["current_topic_name"])
  end
end
