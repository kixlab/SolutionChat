defmodule MicrongoPhxWeb.NGOView do
  use MicrongoPhxWeb, :view

  def current_topic_message(room) do
    case room.room_level do
      0 -> gettext("Starting the discussion session")
      100_000 -> gettext("Ready to take an action!")
      x -> x |> Integer.to_string()
    end
  end

  @spec exact_time(DateTime | nil) :: bitstring()
  def exact_time(datetime) do
    case datetime do
      nil -> gettext("no starting time")
      x -> DateTime.to_string(x)
    end
  end

  @spec fuzzy_time(DateTime | nil) :: bitstring()
  def fuzzy_time(datetime) do
    case datetime do
      nil -> gettext("no starting time")
      x -> Timex.from_now(x)
    end
  end
end
