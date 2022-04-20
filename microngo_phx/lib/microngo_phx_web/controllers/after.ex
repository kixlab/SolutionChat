defmodule MicrongoPhxWeb.AfterController do
  use MicrongoPhxWeb, :controller
  alias MicrongoPhx.Repo

  import Ecto.Query

  plug :put_layout, "survey.html"

  def index(conn, params) do
    part_id = get_session(conn, :part_id)
    conn = if part_id == nil do
      put_session(conn, :part_id, random_string(8))
    else
      conn
    end

    condition = Map.get(params, "condition", "treatment")
    role = Map.get(params, "role", "debater")
    file_name = condition <> "-" <> role <> ".html"

    render(conn, file_name, form: %{
      "room_id" => Map.get(params, "room_id", ""),
      "name" => Map.get(params, "name", "")
    }, part_id: part_id)
  end

  @spec random_string(non_neg_integer()) :: binary()
  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end
end
