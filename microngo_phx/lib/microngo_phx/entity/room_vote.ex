defmodule Room.Vote do
  def init_load(room_state) do
    votes =
      extract_rooms_poll_ids(room_state)
      |> Vote.Query.all_vote_for_ids()
      |> db_list_to_map()

    %{room_state | votes: votes}
  end

  defp extract_rooms_poll_ids(%Room.Server{polls: polls}) do
    Enum.reduce(polls, [], fn {k, p}, acc -> acc ++ [p.id] end)
  end

  defp db_list_to_map(list) do
    Enum.reduce(list, %{}, fn x, acc -> Map.put(acc, x.id, x) end)
  end
end
