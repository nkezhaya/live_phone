defmodule LivePhoneTestApp do
  defmodule Application do
    def start do
      children = [
        LivePhoneTestApp.Endpoint,
        {Phoenix.PubSub, name: LivePhoneTestApp.PubSub}
      ]

      opts = [strategy: :one_for_one, name: LivePhoneTestApp.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end

  defmodule Page do
    use PhoenixHTMLHelpers
    use Phoenix.LiveView

    @impl true
    def handle_params(params, _session, socket) do
      {:noreply, socket |> assign(format?: params["format"] == "1")}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <body>
        <%= csrf_meta_tag() %>

        <.live_component
          module={LivePhone}
          id="phone"
          form={:user}
          field={:phone}
          apply_format?={assigns[:format?]}
          placeholder="Phone"
          preferred={["US", "GB", "CA"]}
          test_counter={assigns[:test_counter]}
        />

        <button id="test_incr" phx-click="incr" />
        <script type="text/javascript" src="/js/phoenix.js">
        </script>
        <script type="text/javascript" src="/js/phoenix_live_view.js">
        </script>
        <script type="text/javascript">
          var module = {exports: {}}
        </script>
        <script type="text/javascript" src="/js/live_phone.js">
        </script>
        <script type="text/javascript">
          (function () {
            var phx = Phoenix;
            var phxLV = LiveView;
            var csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
            var liveSocket = new LiveView.LiveSocket(
              "/live",
              Phoenix.Socket, {
                hooks: {
                  LivePhone: module.exports
                },
                params: {_csrf_token: csrfToken}
              }
            );
            liveSocket.connect();
          })();
        </script>
      </body>
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

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)
      plug(:protect_from_forgery)
      plug(:put_secure_browser_headers)
    end

    scope "/" do
      pipe_through(:browser)
      live("/", Page, :index, as: :index)
    end
  end

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :live_phone

    @session_options [
      store: :cookie,
      key: "_live_phone_key",
      signing_salt: "j40E7Uma"
    ]

    socket("/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]
    )

    plug(Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      body_reader: {BasicSpaceWeb.Plugs.CacheBodyReader, :read_body, []},
      json_decoder: Jason,
      length: 100_000_000
    )

    plug(Plug.Static,
      at: "/",
      from: {:live_phone, "priv/assets"},
      gzip: false,
      only: ~w(css fonts images js favicon.ico robots.txt)
    )

    plug(Plug.RequestId)

    plug(Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Phoenix.json_library()
    )

    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Plug.Session, @session_options)

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
