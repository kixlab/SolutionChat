defmodule MicrongoPhxWeb.PageController do
  use MicrongoPhxWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
