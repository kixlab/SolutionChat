defmodule Discussion.TopicsTest do
  use ExUnit.Case, async: true

  alias Discussion.Topics
  alias Discussion.Topic

  test "Adding a topic to topics" do
    topic_name = "Topic 1"
    topics = Topics.new()
    |> Topics.new_topic(topic_name)
    assert Map.has_key?(topics.data,  "Topic 1")

    answer_name = "Answer 1"
    topic = Topics.add_an_answer_to_topic(topics, topic_name, answer_name)
    |> Topics.get_topic(topic_name)
    assert topic.answers[answer_name].name == answer_name
  end
end
