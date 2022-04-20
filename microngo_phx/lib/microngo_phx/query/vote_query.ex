defmodule Vote.Query do
  import Ecto.Query
  alias MicrongoPhx.Repo

  def all() do
    from(v in Vote, select: v, preload: [])
  end

  # filters
  def where_poll_id_is(query, poll_id) do
    from(v in query, where: v.poll_id == ^poll_id)
  end

  def where_vote_id_are(query, ids) do
    from(v in query, where: v.poll_id in ^ids)
  end

  # actions

  def all_vote_for_ids(ids) do
    all()
    |> where_vote_id_are(ids)
    |> Repo.all()
  end

  def one_vote(poll_id, user_id) do
    all = all()
    query = from(v in all, where: v.poll_id == ^poll_id and v.user_id == ^user_id)
    Repo.one(query)
  end

  def vote(poll_id, entity_id, user_id, value) do
    changes =
      case one_vote(poll_id, user_id) do
        nil ->
          []

        one_vote ->
          {:ok, _} = Repo.delete(one_vote)

          [
            %{
              event: "deleted",
              vote: one_vote
            }
          ]
      end

    {:ok, new_vote} =
      Vote.changeset(%Vote{}, %{
        poll_id: poll_id,
        entity_id: entity_id,
        user_id: user_id,
        value: value
      })
      |> Repo.insert()

    changes ++
      [
        %{
          event: "inserted",
          vote: new_vote
        }
      ]
  end
end
