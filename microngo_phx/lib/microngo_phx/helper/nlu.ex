defmodule NLU.Result do
  defstruct input: nil, intent: nil

  def intent_name(result) do
    if result.intent == nil do
      nil
    else
      result.intent.intent_name
    end
  end

  def probability(result) do
    if result.intent == nil do
      nil
    else
      result.intent.probability
    end
  end

  def input(result) do
      result.input
  end
end

defmodule NLU.Result.Intent do
  defstruct intent_name: nil, probability: nil
end

defmodule NLU do
  def query(message) do
    query = URI.encode_query(%{q: message})
    response = HTTPotion.get "http://nlu:5000/nlu?" <> query
    if response.status_code == 200 do
      parse_nlu(response.body)
    else
      %NLU.Result{
        input: message,
        intent: nil
      }
    end
  end

  def parse_nlu(json_string) do
    json = Poison.decode!(json_string)
    input = Map.get(json, "input")
    intent = case Map.get(json, "intent") do
      nil -> nil
      intent ->
        %NLU.Result.Intent{
          intent_name: Map.get(intent, "intentName"),
          probability: Map.get(intent, "probability")
        }
    end

    IO.inspect %NLU.Result{
      input: input,
      intent: intent
    }

    %NLU.Result{
      input: input,
      intent: intent
    }
  end
end
