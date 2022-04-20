defmodule MicrongoPhx.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(MicrongoPhx.Repo, []),
      # Start the endpoint when the application starts
      supervisor(MicrongoPhxWeb.Endpoint, []),
      # Start your own worker by calling: MicrongoPhx.Worker.start_link(arg1, arg2, arg3)
      # worker(MicrongoPhx.Worker, [arg1, arg2, arg3]),
      supervisor(ChatService.Supervisor, []),
      # supervisor(Problem.Supervisor, []),
      supervisor(MicrongoPhx.Presence, []),
      supervisor(Registry, [:unique, :room_registry], id: :room_registry),
      supervisor(Registry, [:unique, :problem_registry], id: :problem_registry)
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MicrongoPhx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MicrongoPhxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
