defmodule LivePhone.Component do
  @moduledoc """
  The `LivePhone.Component` is a Phoenix LiveView component that can be used
  to prompt users for their phone numbers, and try to make it as simple as possible.

  Usage is pretty simple, and there is an example Phoenix project included in the
  `./example`/  directory of this repository, so feel free to check that out as well.

  ```elixir
    live_component(
      @socket,
      LivePhone.Component,
      id: "phone",
      form: :user,
      field: :phone,
      tabindex: 0,
      preferred: ["US", "CA"]
    )
  ```

  This will result in a form field with the name `user[phone]`. You can specify
  just the `name` manually if desired, but when you add the `form` option the
  name will be generated via `Phoenix.HTML.Form.input_name/2`. So this should
  behave like a regular input field.

  With `preferred` you can set a list of countries that you believe should be
  on top always. The currently selected country will also be on top automatically.

  """
  use Phoenix.LiveComponent
  use Phoenix.HTML

  alias LivePhone.Countries
  alias LivePhone.Country

  alias ExPhoneNumber
  alias ISO

  @impl true
  @spec mount(Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:preferred, fn -> ["US", "GB"] end)
     |> assign_new(:tabindex, fn -> 0 end)
     |> assign_new(:apply_format?, fn -> false end)
     |> assign_new(:value, fn -> "" end)
     |> assign(:is_opened?, false)
     |> assign(:is_valid?, false)}
  end

  @impl true
  @spec update(Phoenix.LiveView.Socket.assigns(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(country: assigns[:country] || hd(assigns[:preferred] || ["US"]))
     |> set_value()}
  end

  @spec set_value(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def set_value(socket) do
    set_value(socket, socket.assigns[:value])
  end

  @spec set_value(Phoenix.LiveView.Socket.t(), String.t()) :: Phoenix.LiveView.Socket.t()
  def set_value(socket, value) do
    value =
      case value do
        "" ->
          case socket.assigns do
            %{form: form, field: field} when not is_nil(form) and not is_nil(field) ->
              input_value(form, field)

            %{value: value} when not is_nil(value) ->
              value

            _ ->
              value
          end

        value ->
          value
      end || ""

    formatted_value = LivePhone.normalize!(value, socket.assigns[:country])
    is_valid? = LivePhone.is_valid?(formatted_value)

    socket =
      with true <- is_valid?,
           {:ok, country} <- LivePhone.get_country(value) do
        without_country_code = String.replace(formatted_value, "+#{country.region_code}", "")

        socket
        |> assign(:country, country.code)
        |> assign(:value, without_country_code)
      else
        _ -> socket |> assign(:value, value)
      end

    socket
    |> format_user_input(formatted_value)
    |> assign(:is_valid?, is_valid?)
    |> assign(:formatted_value, formatted_value)
    |> push_event("change", %{value: formatted_value})
  end

  @impl true
  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("typing", %{"value" => value}, socket) do
    {:noreply,
     socket
     |> set_value(value)}
  end

  def handle_event("select_country", %{"country" => country}, socket) do
    is_valid? = LivePhone.is_valid?(socket.assigns[:formatted_value])

    placeholder =
      if socket.assigns[:country] == country do
        socket.assigns[:placeholder]
      else
        get_placeholder(country)
      end

    {:noreply,
     socket
     |> assign_country(country)
     |> assign(:is_valid?, is_valid?)
     |> assign(:is_opened?, false)
     |> assign(:placeholder, placeholder)
     |> push_event("focus", %{})}
  end

  def handle_event("toggle", _, socket) do
    {:noreply,
     socket
     |> assign(:is_opened?, socket.assigns.is_opened? != true)}
  end

  def handle_event("close", _, socket) do
    {:noreply,
     socket
     |> assign(:is_opened?, false)}
  end

  @spec get_placeholder(String.t()) :: String.t()
  defp get_placeholder(country) do
    country
    |> ExPhoneNumber.Metadata.get_for_region_code()
    |> case do
      %{fixed_line: %{example_number: number}} ->
        number
        |> String.replace(~r/\d/, "5")
        |> ExPhoneNumber.parse(country)
        |> case do
          {:ok, result} ->
            result |> ExPhoneNumber.format(:national)

          _ ->
            ""
        end
    end
  end

  @spec assign_country(Phoenix.LiveView.Socket.t(), String.t()) :: Phoenix.LiveView.Socket.t()
  defp assign_country(socket, country) do
    socket
    |> assign(:country, country)
  end

  @spec format_user_input(Phoenix.LiveView.Socket.t(), String.t()) :: Phoenix.LiveView.Socket.t()
  defp format_user_input(%{assigns: %{apply_format?: false}} = socket, _), do: socket
  defp format_user_input(socket, ""), do: socket
  defp format_user_input(socket, "0"), do: socket
  defp format_user_input(socket, "00"), do: socket

  defp format_user_input(
         %{assigns: %{formatted_value: formatted_value}} = socket,
         formatted_value
       ),
       do: socket

  defp format_user_input(socket, formatted_value) do
    with {:ok, country} <- Countries.get_country(socket.assigns[:country]),
         country_placeholder <- get_placeholder(country.code) do
      without_country_code =
        formatted_value
        |> String.replace("+#{country.region_code}", "")
        |> String.replace(~r/[^0-9]+/, "")
        |> String.replace(~r/^0+/, "")

      country_placeholder =
        country_placeholder
        |> String.replace(~r/[^0-9]+/, " ")
        |> String.replace(~r/^0+/, "")
        |> String.trim()

      {number, remain} =
        Enum.map_reduce(
          to_charlist(country_placeholder),
          to_charlist(without_country_code),
          fn
            ?5, [first | digits] -> {first, digits}
            ?5, [] = digits -> {'•', digits}
            other, digits -> {other, digits}
          end
        )

      user_formatted =
        [number, remain]
        |> List.flatten()
        |> to_string
        |> String.replace(~r/(•.*)/, "")

      socket
      |> push_event("format", %{value: user_formatted})
    else
      _ -> socket
    end
  end

  @spec phone_input(Phoenix.LiveView.Socket.assigns()) :: Phoenix.HTML.Safe.t()
  defp phone_input(assigns) do
    tag(:input,
      type: "text",
      class: "live_phone-input",
      pattern: "[0-9]*",
      inputmode: "numeric",
      value: assigns[:value],
      tabindex: assigns[:tabindex],
      placeholder: assigns[:placeholder] || get_placeholder(assigns[:country]),
      phx_target: assigns[:myself],
      phx_keyup: "typing",
      phx_blur: "close"
    )
  end

  @spec hidden_phone_input(Phoenix.LiveView.Socket.assigns()) :: Phoenix.HTML.Safe.t()
  defp hidden_phone_input(assigns) do
    hidden_input(
      assigns[:form],
      assigns[:field],
      name: assigns[:name] || input_name(assigns[:form], assigns[:field]),
      value: assigns[:formatted_value]
    )
  end

  @spec country_selector(Phoenix.LiveView.Socket.assigns()) :: Phoenix.HTML.Safe.t()
  defp country_selector(assigns) do
    content_tag(:div,
      role: "combobox",
      class: "live_phone-country",
      tabindex: assigns[:tabindex],
      phx_target: assigns[:myself],
      phx_click: "toggle",
      aria_owns: "live_phone-country-list-#{assigns[:id]}",
      aria_expanded: if(assigns[:is_opened?], do: true, else: false)
    ) do
      emoji = LivePhone.emoji_for_country(assigns[:country])

      region_code =
        ExPhoneNumber.Metadata.get_for_region_code(assigns[:country])
        |> case do
          nil -> ""
          code -> "+#{code.country_code}"
        end

      "#{emoji} #{region_code}"
    end
  end

  @spec country_list(%{is_opened?: boolean()}) :: nil
  defp country_list(%{is_opened?: false}), do: nil

  @spec country_list(%{country: String.t()}) :: Phoenix.HTML.Safe.t()
  defp country_list(%{country: country} = assigns) do
    preferred_countries = [country | assigns[:preferred]]

    content_tag(:ul,
      role: "listbox",
      class: "live_phone-country-list",
      id: "live_phone-country-list-#{assigns[:id]}"
    ) do
      countries = Countries.list_countries(preferred_countries)
      last_preferred = countries |> Enum.filter(& &1.preferred) |> List.last()

      for country <- countries do
        output = [country_list_item(assigns, country)]

        if last_preferred == country do
          output ++ [country_list_separator()]
        else
          output
        end
      end
    end
  end

  @spec country_list_item(Phoenix.LiveView.Socket.assigns(), Country.t()) :: Phoenix.HTML.Safe.t()
  defp country_list_item(assigns, %Country{} = country) do
    selected? = country.code == assigns[:country]

    class = ["live_phone-country-item"]
    class = if selected?, do: ["selected" | class], else: class
    class = if country.preferred, do: ["preferred" | class], else: class

    content_tag(:li,
      role: "option",
      class: Enum.join(class, " "),
      aria_selected: if(selected?, do: "true", else: "false"),
      phx_target: assigns[:myself],
      phx_click: "select_country",
      phx_value_country: country.code
    ) do
      [
        content_tag(:span, country.flag_emoji, class: "live_phone-country-item-flag"),
        content_tag(:span, country.name, class: "live_phone-country-item-name"),
        content_tag(:span, "+" <> country.region_code, class: "live_phone-country-item-code")
      ]
    end
  end

  @spec country_list_separator() :: Phoenix.HTML.Safe.t()
  defp country_list_separator do
    content_tag(:li,
      role: "separator",
      aria_disabled: "true",
      class: "live_phone-country-separator"
    ) do
    end
  end
end
