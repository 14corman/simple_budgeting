defmodule SimpleBudgeting.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SimpleBudgetingWeb.Telemetry,
      SimpleBudgeting.Repo,
      {DNSCluster, query: Application.get_env(:simple_budgeting, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SimpleBudgeting.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: SimpleBudgeting.Finch},
      # Start a worker by calling: SimpleBudgeting.Worker.start_link(arg)
      # {SimpleBudgeting.Worker, arg},
      # Start to serve requests, typically the last entry
      SimpleBudgetingWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SimpleBudgeting.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SimpleBudgetingWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
