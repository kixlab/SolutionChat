defmodule FreqDict do
  def new do
    %{}
  end

  def add(dict, token) do
    case Map.get(dict, token) do
      nil -> Map.put(dict, token, 0)
      count -> Map.put(dict, token, count+1)
    end
  end

  def count(dict, token) do
    case Map.get(dict, token) do
      nil -> 0
      count -> count
    end
  end
end
