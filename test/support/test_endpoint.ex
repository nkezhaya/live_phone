defmodule LivePhoneTestApp do
  defmodule Page do
    import Phoenix.LiveView.Helpers

    use Phoenix.HTML
    use Phoenix.LiveView

    @impl true
    def handle_params(_params, _session, socket) do
      {:noreply, socket}
    end

    @impl true
    def render(assigns) do
      ~L"""
      <%= live_component(
        assigns[:socket],
        LivePhone.Component,
        id: "phone",
        form: :user,
        field: :phone,
        placeholder: "Phone",
        preferred: ["US", "GB", "CA"],
        test_counter: assigns[:test_counter]
      ) %>

      <button id="test_incr" phx-click="incr" />
      """
    end

    @impl true
    def handle_event("incr", _params, socket) do
      current = (socket.assigns[:test_counter] || 0) + 1
      {:noreply, assign(socket, test_counter: current)}
    end
  end

  defmodule Router do
    use Phoenix.Router

    import Plug.Conn
    import Phoenix.LiveView.Router

    live("/", Page, :index, as: "index")
  end

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :live_phone

    plug(Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      body_reader: {BasicSpaceWeb.Plugs.CacheBodyReader, :read_body, []},
      json_decoder: Jason,
      length: 100_000_000
    )

    plug(Router)
  end

  defmodule User do
    use Ecto.Schema
    import Ecto.Changeset

    schema "users" do
      field(:phone, :string)
    end

    def changeset(struct \\ %__MODULE__{}, params \\ %{}) do
      struct
      |> cast(params, [:phone])
    end
  end
end
