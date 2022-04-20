defmodule MicrongoPhxWeb.RoomApiView do
  use MicrongoPhxWeb, :view

  def render("create.json", %{result: {:ok, room}}) do
    room_to_map(room)
  end

  def room_to_map(room) do
    %{
      id: room.id,
      title: room.title
    }
  end
end
