defmodule Problem.Logic.Adder do
  def make_problem_if_not_exist(room_id, local_id, title) do
    exist =
      case Problem.Logic.get_problem_by_room_and_title(room_id, title) do
        %Problem{} -> {:error, :already_exists}
        nil -> nil
      end

    with nil <- exist,
         {:ok, problem} = Problem.Logic.make_new_problem(room_id, local_id, title) do
      {:ok, problem}
    end
  end
end
