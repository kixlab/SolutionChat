defmodule MicrongoPhxWeb.NGOLookupView do
  use MicrongoPhxWeb, :view

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
