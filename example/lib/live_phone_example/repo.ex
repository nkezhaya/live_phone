defmodule LivePhoneExample.Repo do
  use Ecto.Repo,
    otp_app: :live_phone_example,
    adapter: Ecto.Adapters.Postgres
end
