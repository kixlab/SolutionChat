defmodule Problem.Logic do
  alias MicrongoPhx.Repo
  import Ecto.Query

  def make_problem_if_not_exist(room_id, local_id, title) do
    %{
      params: %{
        room_id: room_id,
        local_id: local_id,
        title: title
      },
      tasks: %{
        dup_check: :ready,
        insert_check: :ready
      }
    }
    |> make_problem_if_not_exist()
  end

  defp make_problem_if_not_exist(%{tasks: %{dup_check: :ready}} = state) do
    %{
      state
      | tasks: %{
          state.tasks
          | dup_check: get_problem_by_room_and_title(state.params.room_id, state.params.title)
        }
    }
    |> make_problem_if_not_exist()
  end

  defp make_problem_if_not_exist(%{tasks: %{dup_check: %Problem{}}}) do
    {:error, :already_exists}
  end

  defp make_problem_if_not_exist(%{tasks: %{dup_check: nil}} = state) do
    %{state | tasks: %{state.tasks | dup_check: :done}}
    |> make_problem_if_not_exist()
  end

  defp make_problem_if_not_exist(%{tasks: %{insert_check: :ready}} = state) do
    %{
      state
      | tasks: %{
          state.tasks
          | insert_check:
              make_new_problem(state.params.room_id, state.params.local_id, state.params.title)
        }
    }
    |> make_problem_if_not_exist()
  end

  defp make_problem_if_not_exist(%{tasks: %{insert_check: {:ok, problem}}}) do
    {:ok, problem}
  end

  defp make_problem_if_not_exist(%{tasks: %{insert_check: {:error, reason}}}) do
    {:error, reason}
  end

  def make_new_problem(room_id, local_id, title) do
    Problem.changeset(%Problem{}, %{
      room_id: room_id,
      local_id: local_id,
      title: title
    })
    # expect {:ok, %Problem}
    |> Repo.insert()
  end

  def all_by_param(param_list) do
    q = gen_where(nil, param_list)
    Repo.all(q)
  end

  def gen_where(nil, param_list) do
    query = from(p in Problem, select: p)
    gen_where(query, param_list)
  end

  def gen_where(query, []) do
    query
  end

  def gen_where(query, [{:room_id, val} | tail]) do
    q = from(p in query, where: p.room_id == ^val)
    gen_where(q, tail)
  end

  def gen_where(query, [{:id, id} | tail]) do
    q = from(p in query, where: p.id == ^id)
    gen_where(q, tail)
  end

  def get_problem_by_room_and_title(room_id, title) do
    Repo.one(from(p in Problem, where: p.room_id == ^room_id and p.title == ^title))
  end

  def safe_map_list(enum) do
    Enum.map(enum, fn problem -> Problem.Logic.safe_map(problem) end)
  end

  def safe_map(%Problem{} = problem) do
    %{
      id: problem.id,
      local_id: problem.local_id,
      title: problem.title
    }
  end
end
