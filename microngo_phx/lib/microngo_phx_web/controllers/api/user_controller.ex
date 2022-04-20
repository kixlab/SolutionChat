defmodule MicrongoPhxWeb.UserApiController do
  use MicrongoPhxWeb, :controller

  def create(conn, params) do
    result = User.Logic.signup(params)
    render(conn, "create.json", result: result)
  end

  def token(conn, _params) do
    name = MicrongoPhxWeb.Helper.Name.generate_name() <> Integer.to_string(Enum.random(1..99))
    {:ok, user} =
      User.Logic.signup(%{
        "email" => name,
        "password" => name,
        "username" => name
      })
    token = Phoenix.Token.sign(conn, "user socket", user.id)
    render(conn, "token.json", result: {:ok, token})
  end
end
