defmodule MicrongoPhxWeb.LandingController do
  use MicrongoPhxWeb, :controller
  alias MicrongoPhx.Repo

  import Ecto.Query

  plug :put_layout, "survey.html"

  def index(conn, _params) do
    part_id = get_session(conn, :part_id)
    conn = if part_id == nil do
      put_session(conn, :part_id, random_string(8))
    else
      conn
    end
    part_id = get_session(conn, :part_id)

    render(conn, "index.html", part_id: part_id)
  end

  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end
end
