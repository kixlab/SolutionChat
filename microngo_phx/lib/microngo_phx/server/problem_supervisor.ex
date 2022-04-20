defmodule Problem.Supervisor do
  import Supervisor.Spec

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_problem(optionList) do
    Supervisor.start_child(__MODULE__, [optionList])
  end

  #####################

  def init(:ok) do
    children = [
      worker(Problem.Server, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
