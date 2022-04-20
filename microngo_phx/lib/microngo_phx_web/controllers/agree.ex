defmodule MicrongoPhxWeb.AgreeController do
  use MicrongoPhxWeb, :controller

  plug :put_layout, "blank.html"

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
