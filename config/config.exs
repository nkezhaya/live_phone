import Config

config :phoenix, :json_library, Jason

if config_env() == :test do
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
  config :logger, level: :warning

  config :wallaby,
    otp_app: :live_phone,
    driver: Wallaby.Chrome,
    base_url: "http://localhost:4002",
    chromedriver: [headless: true]
end
