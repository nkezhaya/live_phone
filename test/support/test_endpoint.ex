defmodule LivePhoneTestApp do
  defmodule Page do
    import Phoenix.LiveView.Helpers

    use Phoenix.HTML
    use Phoenix.LiveView

    @impl true
    def render(assigns) do
      ~L"""
      <%= live_component(
        assigns[:socket],
        LivePhone.Component,
        id: "phone",
        form: :user,
        field: :phone,
        preferred: ["US", "GB", "CA"]
      ) %>
      """
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
    plug(Router)
  end
end
