defmodule Envelop.Errors do
  def new do
    %{errors: []}
  end

  def add_error_msg(errors, message, data \\ nil)

  def add_error_msg(nil, message, data) do
    error = %{
      name: message,
      data: data
    }

    %{errors: [error]}
  end

  def add_error_msg(%{errors: _} = errors, message, data) do
    error = %{
      name: message,
      data: data
    }

    %{errors | errors: errors.errors ++ [error]}
  end
end
