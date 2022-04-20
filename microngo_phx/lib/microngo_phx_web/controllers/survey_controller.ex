defmodule MicrongoPhxWeb.SurveyController do
  use MicrongoPhxWeb, :controller

  import Ecto.Query

  plug :put_layout, "survey.html"

  def index(conn, params) do
    render(conn, "index.html", form: %{
      "room_id" => Map.get(params, "room_id", ""),
      "name" => Map.get(params, "name", "")
    })
  end

  def create(conn, params) do
    error = cond do
      Map.get(params, "action_type") == nil -> "Number 6 is not selected"
      Map.get(params, "agree") == nil -> "Number 7 is not selected"
      Map.get(params, "action_further") == nil -> "Number 8 is not selected"
      Map.get(params, "easy") == nil -> "Number 9 is not selected"
      Map.get(params, "confusion") == nil -> "Number 10 is not selected"
      Map.get(params, "confusion2") == nil -> "Number 11 is not selected"
      Map.get(params, "helpful") == nil -> "Number 13 is not selected"
      Map.get(params, "enjoy") == nil -> "Number 14 is not selected"
      Map.get(params, "room_id") == nil -> "Number 15 is blank"
      Map.get(params, "name") == nil -> "Number 16 is blank"
      true -> nil
    end

    if error != nil do
      render(conn, "index.html", form: Map.put(params, "error", error ))
    else
      {:ok, json} = Poison.encode(params)
      field = %{
        room_id: Map.get(params, "room_id"),
        name: Map.get(params, "name"),
        json: json,
        code: random_string(6)
      }
      changeset = MicrongoPhx.Surveys.Survey.changeset(%MicrongoPhx.Surveys.Survey{}, field)
      query = from a in MicrongoPhx.Surveys.Survey, where: (a.room_id == ^changeset.changes.room_id) and (a.name == ^changeset.changes.name)
      case MicrongoPhx.Repo.all(query) do
        [] ->
          case MicrongoPhx.Repo.insert(changeset) do
            {:ok, inserted} ->
              render(conn, "thank_you.html", code: inserted.code)
            _ ->
              render(conn, "index.html", form: Map.put(params, "error", "DB error try again" ))
          end
        _ ->
          render(conn, "index.html", form: Map.put(params, "error", "Already submitted" ))
      end
    end
  end

  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end
end
