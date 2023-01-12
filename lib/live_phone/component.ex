defmodule LivePhone.Component do
  @moduledoc """
  The `LivePhone.Component` is a Phoenix LiveView component that can be used
  to prompt users for their phone numbers, and try to make it as simple as possible.

  Usage is pretty simple, and there is an example Phoenix project included in the
  `./example`/  directory of this repository, so feel free to check that out as well.

  ```elixir
  <.live_component
    module={LivePhone.Component}
    id="phone"
    form={:user}
    field={:phone}
    tabindex={0}
    preferred={["US", "CA"]} />
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

  @impl true
  @spec mount(Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:preferred, fn -> ["US", "GB"] end)
     |> assign_new(:tabindex, fn -> 0 end)
     |> assign_new(:apply_format?, fn -> false end)
     |> assign_new(:value, fn -> "" end)
     |> assign_new(:is_opened?, fn -> false end)
     |> assign_new(:is_valid?, fn -> false end)}
  end

  @impl true
  @spec update(Phoenix.LiveView.Socket.assigns(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def update(assigns, socket) do
    current_country =
      assigns[:country] || socket.assigns[:country] || hd(assigns[:preferred] || ["US"])

    masks =
      if assigns[:apply_format?] do
        current_country
        |> get_masks()
        |> Enum.join(",")
      end

    socket =
      socket
      |> assign(assigns)
      |> assign_country(current_country)
      |> assign(:masks, masks)

    {:ok, set_value(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={"live_phone #{if @is_valid?, do: " live_phone-valid"}"} id={"live_phone-#{@id}"} phx-hook="LivePhone">
      <.country_selector tabindex={@tabindex} target={@myself} is_opened?={@is_opened?} country={@country} />

      <input
        type="tel"
        class="live_phone-input"
        value={assigns[:value]}
        tabindex={assigns[:tabindex]}
        placeholder={assigns[:placeholder] || get_placeholder(assigns[:country])}
        data-masks={@masks}
        phx-target={@myself}
        phx-keyup="typing"
        phx-blur="close"
      >

      <%= hidden_input(
        assigns[:form],
        assigns[:field],
        name: assigns[:name] || input_name(assigns[:form], assigns[:field]),
        value: assigns[:formatted_value]
      ) %>

      <%= if @is_opened? do %>
        <.country_list country={@country} preferred={@preferred} id={@id} target={@myself} />
      <% end %>
    </div>
    """
  end

  @spec set_value(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def set_value(socket) do
    set_value(socket, socket.assigns[:value])
  end

  @spec set_value(Phoenix.LiveView.Socket.t(), String.t()) :: Phoenix.LiveView.Socket.t()
  def set_value(socket, value) do
    value =
      case value do
        empty when empty in ["", nil] ->
          case socket.assigns do
            %{form: form, field: field} when not is_nil(form) and not is_nil(field) ->
              input_value(form, field)

            %{value: assigns_value} when not is_nil(assigns_value) ->
              value

            _ ->
              value
          end

        found_value ->
          found_value
      end || ""

    formatted_value = LivePhone.normalize!(value, socket.assigns[:country])
    value = apply_mask(value, socket.assigns[:country])
    is_valid? = LivePhone.is_valid?(formatted_value)

    push? = socket.assigns[:formatted_value] != formatted_value

    socket
    |> assign(:is_valid?, is_valid?)
    |> assign(:value, value)
    |> assign(:formatted_value, formatted_value)
    |> then(fn socket ->
      if push? do
        push_event(socket, "change", %{
          id: "live_phone-#{socket.assigns.id}",
          value: formatted_value
        })
      else
        socket
      end
    end)
  end

  defp apply_mask(value, _country) when value in [nil, ""], do: value

  defp apply_mask(value, country) do
    case ExPhoneNumber.parse(value, country) do
      {:ok, phone_number} ->
        metadata = ExPhoneNumber.Metadata.get_for_region_code(country)

        national_significant_number =
          ExPhoneNumber.Model.PhoneNumber.get_national_significant_number(phone_number)

        ExPhoneNumber.Formatting.format_nsn(
          national_significant_number,
          metadata,
          :international
        )

      _ ->
        ""
    end
  end

  @impl true
  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("typing", %{"value" => value}, socket) do
    {:noreply, set_value(socket, value)}
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
     |> push_event("focus", %{id: "live_phone-#{socket.assigns.id}"})}
  end

  def handle_event("toggle", _, socket) do
    {:noreply, assign(socket, :is_opened?, socket.assigns.is_opened? != true)}
  end

  def handle_event("close", _, socket) do
    {:noreply, assign(socket, :is_opened?, false)}
  end

  @spec get_placeholder(String.t()) :: String.t()
  defp get_placeholder(country) do
    country
    |> ExPhoneNumber.Metadata.get_for_region_code()
    |> case do
      %{country_code: country_code, fixed_line: %{example_number: number}} ->
        number
        |> String.replace(~r/\d/, "5")
        |> ExPhoneNumber.parse(country)
        |> case do
          {:ok, result} ->
            result
            |> ExPhoneNumber.format(:international)
            |> String.replace(~r/^(\+|00)#{country_code}/, "")
            |> String.trim()

          _ ->
            ""
        end
    end
  end

  @spec get_masks(String.t()) :: [String.t()]
  defp get_masks(country) do
    metadata = ExPhoneNumber.Metadata.get_for_region_code(country)

    # Iterate through all metadata to find phone number descriptions
    # with example numbers only, and return those example numbers
    metadata
    |> Map.from_struct()
    |> Enum.map(fn
      {_, %ExPhoneNumber.Metadata.PhoneNumberDescription{} = desc} -> desc.example_number
      _other -> nil
    end)
    |> Enum.filter(& &1)

    # Parse all example numbers with the country and only keep valid ones
    |> Enum.map(&ExPhoneNumber.parse(&1, country))
    |> Enum.map(fn
      {:ok, parsed} -> parsed
      _other -> nil
    end)
    |> Enum.filter(& &1)

    # Format all parsed numbers with the international format
    # but removing the leading country_code. Transform all digits to X
    # to be used for a mask
    |> Enum.map(&ExPhoneNumber.format(&1, :international))
    |> Enum.map(&String.replace(&1, ~r/^(\+|00)#{metadata.country_code}/, ""))
    |> Enum.map(&String.replace(&1, ~r/\d/, "X"))
    |> Enum.map(&String.trim/1)

    # And make sure we only have unique ones
    |> Enum.uniq()
  end

  @spec assign_country(Phoenix.LiveView.Socket.t(), Country.t() | String.t()) ::
          Phoenix.LiveView.Socket.t()
  defp assign_country(socket, %Country{code: country}), do: assign_country(socket, country)
  defp assign_country(socket, country), do: assign(socket, :country, country)

  defp country_selector(assigns) do
    region_code =
      ExPhoneNumber.Metadata.get_for_region_code(assigns[:country])
      |> case do
        nil -> ""
        code -> "+#{code.country_code}"
      end

    assigns = assign(assigns, :region_code, region_code)

    ~H"""
    <div class="live_phone-country" tabindex={@tabindex} phx-target={@target} phx-click="toggle" aria-owns="live_phone-country-list-#{@id}" aria-expanded={to_string(@is_opened?)} role="combobox">
      <span class="live_phone-country-flag"><%= LivePhone.emoji_for_country(@country) %></span>
      <span class="live_phone-country-code"><%= @region_code %></span>
    </div>
    """
  end

  defp country_list(assigns) do
    assigns =
      if assigns[:country] do
        assign(assigns, :preferred, [assigns[:country] | assigns[:preferred]])
      else
        assigns
      end

    assigns =
      assign_new(assigns, :countries, fn -> Countries.list_countries(assigns[:preferred]) end)

    assigns =
      assign_new(assigns, :last_preferred, fn ->
        assigns[:countries]
        |> Enum.filter(& &1.preferred)
        |> List.last()
      end)

    ~H"""
    <ul class="live_phone-country-list" id={"live_phone-country-list-#{@id}"} role="listbox">
      <%= for country <- @countries do %>
        <.country_list_item country={country} current_country={@country} target={@target} />

        <%= if country == @last_preferred do %>
          <li aria-disabled="true" class="live_phone-country-separator" role="separator">
          </li>
        <% end %>
      <% end %>
    </ul>
    """
  end

  defp country_list_item(assigns) do
    selected? = assigns[:country].code == assigns[:current_country]
    assigns = assign(assigns, :selected?, selected?)

    class = ["live_phone-country-item"]
    class = if assigns[:selected?], do: ["selected" | class], else: class
    class = if assigns[:country].preferred, do: ["preferred" | class], else: class

    assigns = assign(assigns, :class, class)

    ~H"""
    <li aria-selected={to_string(@selected?)} class={@class} phx-click="select_country" phx-target={@target} phx-value-country={@country.code} role="option">
      <span class="live_phone-country-item-flag"><%= @country.flag_emoji %></span>
      <span class="live_phone-country-item-name"><%= @country.name %></span>
      <span class="live_phone-country-item-code">+<%= @country.region_code %></span>
    </li>
    """
  end
end
