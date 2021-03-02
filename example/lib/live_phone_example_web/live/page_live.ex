defmodule LivePhoneExampleWeb.PageLive do
  use LivePhoneExampleWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:phone_number, "")
     |> assign(:valid?, false)}
  end

  @impl true
  def handle_event("change", %{"user" => %{"phone" => phone}}, socket) do
    {:noreply,
     socket
     |> assign(:phone_number, phone)
     |> assign(:valid?, LivePhone.is_valid?(phone))}
  end
end
