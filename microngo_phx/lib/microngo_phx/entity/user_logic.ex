defmodule User.Logic do
  import Ecto.Query
  alias MicrongoPhx.Repo

  def signup(params) do
    changeset = User.changeset(%User{}, params)
    MicrongoPhx.Repo.insert(changeset)
  end

  def get_by_login_crediential(email, password) do
    case Repo.all(from(u in User, where: u.email == ^email and u.password == ^password)) do
      [%User{} = user] -> {:ok, user}
      _ -> {:error, :no_match}
    end
  end
end
