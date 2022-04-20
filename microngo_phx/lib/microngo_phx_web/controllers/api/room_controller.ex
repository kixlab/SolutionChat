defmodule MicrongoPhxWeb.RoomApiController do
  use MicrongoPhxWeb, :controller

  def create(conn, params) do
    changeset = DB.Room.changeset(%DB.Room{}, params)
    inserted = MicrongoPhx.Repo.insert(changeset)
    render(conn, "create.json", result: inserted)
  end
end
