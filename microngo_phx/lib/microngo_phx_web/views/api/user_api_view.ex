defmodule MicrongoPhxWeb.UserApiView do
  use MicrongoPhxWeb, :view

  def render("create.json", %{result: {:ok, room}}) do
    User.to_map(room)
  end

  def render("create.json", %{result: {:error, reason}}) do
    %{error: reason}
  end

  def render("token.json", %{result: {:ok, token}}) do
    %{token: token}
  end

  def render("token.json", %{result: {:error, reason}}) do
    %{error: reason}
  end
end
