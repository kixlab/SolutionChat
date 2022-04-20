defmodule MessageLink.Logic do
  def new(message_id, problem_id) do
    MessageLink.changeset(%MessageLink{}, %{
      message_id: message_id,
      problem_id: problem_id
    })
  end
end
