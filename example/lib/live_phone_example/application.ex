defmodule LivePhoneExample.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LivePhoneExampleWeb.Telemetry,
      LivePhoneExample.PhoneStorage,
      {DNSCluster, query: Application.get_env(:live_phone_example, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LivePhoneExample.PubSub},
      # Start a worker by calling: LivePhoneExample.Worker.start_link(arg)
      # {LivePhoneExample.Worker, arg},
      # Start to serve requests, typically the last entry
      LivePhoneExampleWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LivePhoneExample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LivePhoneExampleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
