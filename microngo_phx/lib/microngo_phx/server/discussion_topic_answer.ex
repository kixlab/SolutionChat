defmodule Discussion.Topic.Answer do
  def new(name) do
    %{"name" => name, "votes" => []}
  end
end
