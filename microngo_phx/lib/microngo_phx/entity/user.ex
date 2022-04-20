defmodule User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:email, :string)
    field(:password, :string)
    field(:username, :string)
    timestamps()
  end

  @fields ~w(email password username)

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> validate_required([:email, :password, :username])
  end

  def to_map(%User{} = user) do
    %{
      email: user.email,
      password: user.password,
      username: user.username
    }
  end
end
