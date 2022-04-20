defmodule MicrongoPhxWeb.JoinController do
  use MicrongoPhxWeb, :controller
  alias MicrongoPhx.Repo
  import Ecto.Query
  plug :put_layout, "blank.html"

  def index(conn, _params) do
    redirect(conn, to: "/tut/index.html")
  end

  def create(conn, params) do
    redirect(conn, to: "/room/index.html?room=#{params["roomID"]}")
  end

  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end
end
