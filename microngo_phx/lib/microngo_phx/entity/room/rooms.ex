defmodule Rooms do
  import Ecto.Query
  alias DB.Room
  alias MicrongoPhx.Repo

  def whole() do
    from(e in Room, select: e, preload: [])
  end

  def order_by_id(query) do
    from(e in query, order_by: [desc: e.id])
  end
end
