import Config

config :phoenix, :json_library, Jason

if Mix.env() == :test do
  # We don't run a server during test. If one is required,
  # you can enable the server option below.
  config :live_phone, LivePhoneTestApp.Endpoint,
    http: [port: 4002],
    url: [host: "localhost"],
    secret_key_base: "DC7N7zO/AVr5qqVk+ZRAm1PM4arGnoZ7847JlrRmUknGCbFIdcL14+wF9Ws085mU",
    live_view: [signing_salt: "NsyigQtD"],
    pubsub_server: LivePhoneTestApp.PubSub,
    server: true

  # Print only warnings and errors during test
  config :logger, level: :warn

  config :hound,
    driver: "chrome_driver",
    browser: "chrome_headless",
    app_port: 4002,
    host: "http://127.0.0.1",
    path_prefix: "wd/hub/"
end
