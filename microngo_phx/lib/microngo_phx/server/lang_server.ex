defmodule Lang do
  defstruct lang_map: %{}
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: :lang_server)
  end

  def init(_) do
    GenServer.cast(:lang_server, :load_lang_file)
    {:ok, %{}}
  end

  def t(locale, plain, data) do
    GenServer.call(:lang_server, {:t, locale, plain, data})
  end

  def handle_cast(:load_lang_file, _) do
    {:ok, payload} = File.read("lang.json")
    {:ok, json_map} = Poison.decode(payload)
    {:noreply, json_map}
  end


  def handle_call({:t, locale, plain, _data}, _from, state) do
    dict = Map.get(state, plain)
    if dict == nil do
      {:reply, plain, state}
    else
      target = Map.get(dict, locale)
      if target == nil do
        {:reply, plain, state}
      else
        {:reply, target, state}
      end
    end
  end
end
