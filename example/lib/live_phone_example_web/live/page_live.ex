defmodule LivePhoneExampleWeb.PageLive do
  use LivePhoneExampleWeb, :live_view

  alias LivePhoneExample.PhoneStorage

  @data %{phone: :string, phone2: :string}

  @impl true
  def mount(_params, _session, socket) do
    phone = PhoneStorage.get_phone()
    changeset = Ecto.Changeset.change({%{phone: phone}, @data})

    {:ok,
     socket
     |> assign(:phone_number, phone)
     |> assign(:changeset, changeset)
     |> assign(:valid?, false)}
  end

  @impl true
  def handle_event("change", %{"phone" => %{"phone" => phone} = params}, socket) do
    {:noreply,
     socket
     |> assign(:phone_number, phone)
     |> assign(:changeset, Ecto.Changeset.change({params, @data}))
     |> assign(:valid?, LivePhone.Util.valid?(phone))}
  end

  def handle_event("submit", %{"phone" => %{"phone" => phone}}, socket) do
    PhoneStorage.put_phone(phone)

    {:noreply, redirect(socket, to: "/")}
  end
end
