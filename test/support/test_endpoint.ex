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
        placeholder: "Phone",
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
