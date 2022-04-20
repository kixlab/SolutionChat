defmodule Discussion.Topic do
  alias Discussion.Topic.Answer

  @spec new(String.t) :: %{}
  def new(name, opts \\ []) do
    %{
      "name" => name, "answers" => %{}, "orders" => [],
      "completed" => false,
      "voting" => false,
      "kind" => Keyword.get(opts, :kind),
      "page" => Keyword.get(opts, :page) || 0,
      "placeholder" => Keyword.get(opts, :placeholder) || ""
    }
  end

  def add_answer(topic, answer_name) do
    if Map.has_key?(topic["answers"], answer_name) do
      topic
    else
      new_orders = topic["orders"] ++ [answer_name]
      %{topic|
        "orders" => new_orders,
        "answers" => Map.put(topic["answers"], answer_name, Answer.new(answer_name))
      }
    end
  end

  def start_voting(topic) do
    %{topic|
      "voting" => true
    }
  end

  def vote_on_answer(topic, answer_name, user_name, up) do
    if Map.has_key?(topic["answers"], answer_name) == false do
      topic
    else
      answer = Map.get(topic["answers"], answer_name)
      if answer == nil do
        topic
      else
        new_answer = if up == true do
          %{answer|
            "votes" => Enum.uniq(answer["votes"] ++ [user_name])
          }
        else
          %{answer|
            "votes" => Enum.uniq(answer["votes"] -- [user_name])
          }
        end
        %{topic|
          "answers" => Map.put(topic["answers"], answer_name, new_answer)
        }
      end
    end
  end

  def mark_as_done(topic) do
    new_orders = if Enum.count(topic["orders"]) > 0 do
      topic["orders"]
      |> Enum.sort(fn (x, y) ->
        x_count = Map.get(topic["answers"], x)
        |> Map.get("votes")
        |> Enum.count()
        y_count = Map.get(topic["answers"], y)
        |> Map.get("votes")
        |> Enum.count()

        x_count >= y_count
      end)
    else
      topic["orders"]
    end

    %{topic|
      "completed" => true,
      "orders" => new_orders
    }
  end

  def reopen(topic) do
    %{topic|
      "completed" => false,
      "voting" => false,
    }
  end

  def delete_answer(topic, answer_name) do
    %{topic|
      "answers" => Map.delete(topic["answers"], answer_name),
      "orders" => topic["orders"] -- [answer_name],
    }
  end
end
