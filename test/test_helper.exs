ExUnit.start()

children = [
  LivePhoneTestApp.Endpoint
]

opts = [strategy: :one_for_one, name: LivePhoneTestApp.Supervisor]
Supervisor.start_link(children, opts)
