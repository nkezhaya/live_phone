defmodule LivePhone.Component do
  @moduledoc """
  Documentation for `LivePhone`.
  """
  use Phoenix.LiveComponent
  use Phoenix.HTML

  alias LivePhone.Countries
  alias LivePhone.Country

  alias ExPhoneNumber
  alias ISO

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:preferred, fn -> ["US", "GB"] end)
     |> assign_new(:tabindex, fn -> 0 end)
     |> assign_country("US")
     |> assign(:is_opened?, false)
     |> assign(:is_valid?, false)
     |> assign(:value, "")
     |> assign(:formatted_value, "")}
  end

  @impl true
  def update(assigns, socket) do
    preferred = assigns[:preferred] || ["US"]
    default_country = hd(preferred)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_country(default_country)}
  end

  @impl true
  def handle_event("typing", %{"value" => value}, socket) do
    formatted_value = LivePhone.normalize(value, socket.assigns[:country])
    is_valid? = LivePhone.is_valid?(formatted_value)

    {:noreply,
     socket
     |> assign(:value, value)
     |> assign(:is_valid?, is_valid?)
     |> assign(:formatted_value, formatted_value)
     |> push_event("change", %{value: formatted_value})}
  end

  def handle_event("select_country", %{"country" => country}, socket) do
    is_valid? = LivePhone.is_valid?(socket.assigns[:formatted_value])

    {:noreply,
     socket
     |> assign_country(country)
     |> assign(:is_valid?, is_valid?)
     |> assign(:is_opened?, false)
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

  defp assign_country(socket, country) do
    socket
    |> assign(:country, country)
    |> assign(:placeholder, get_placeholder(country))
  end

  defp phone_input(assigns) do
    tag(:input,
      type: "text",
      class: "live_phone-input",
      value: assigns[:value],
      tabindex: assigns[:tabindex],
      placeholder: assigns[:placeholder],
      phx_target: assigns[:myself],
      phx_keyup: "typing",
      phx_blur: "close"
    )
  end

  defp hidden_phone_input(assigns) do
    hidden_input(
      assigns[:form],
      assigns[:field],
      name: assigns[:name] || input_name(assigns[:form], assigns[:field]),
      value: assigns[:formatted_value]
    )
  end

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

  defp country_list(%{is_opened?: false}), do: nil

  defp country_list(assigns) do
    preferred_countries =
      case assigns[:country] do
        "" -> assigns[:preferred]
        nil -> assigns[:preferred]
        country -> [country | assigns[:preferred]]
      end

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

  defp country_list_separator() do
    content_tag(:li,
      role: "separator",
      aria_disabled: "true",
      class: "live_phone-country-separator"
    ) do
    end
  end
end
