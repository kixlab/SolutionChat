defmodule MicrongoPhxWeb.SurveyView do
  use MicrongoPhxWeb, :view

  def checked(form, field, value) do
    if Map.get(form, field, "") == value, do: "checked", else: ""
  end

  def check(form, field, value) do
    if Map.get(form, field, "") == value do
      {:safe, "type=\"radio\" name=\"#{field}\" value=\"#{value}\" checked"}
    else
      {:safe, "type=\"radio\" name=\"#{field}\" value=\"#{value}\""}
    end
  end

end
