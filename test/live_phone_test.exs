defmodule LivePhoneTest do
  use ExUnit.Case
  import Phoenix.{LiveViewTest, ConnTest}
  alias Phoenix.HTML.FormData
  doctest LivePhone

  @endpoint LivePhoneTestApp.Endpoint

  setup do
    [conn: Phoenix.ConnTest.build_conn()]
  end

  test "renders component" do
    component = render_live_phone(id: "livephone")
    assert component =~ "id=\"live_phone-livephone\""
  end

  test "support setting tabindex" do
    component = render_live_phone(id: "livephone", tabindex: 42)
    assert component =~ "tabindex=\"42\""
  end

  test "support setting name" do
    component = render_live_phone(id: "livephone", name: :phone)
    assert component =~ "name=\"phone\""
  end

  test "support setting form and field" do
    component = render_live_phone(id: "livephone", form: :user, field: :phone)

    assert component =~ "name=\"user[phone]\""
  end

  test "support setting placeholder" do
    component = render_live_phone(id: "livephone", placeholder: "Phone Number")

    assert component =~ "placeholder=\"Phone Number\""
  end

  test "support setting mask (single)" do
    component =
      render_live_phone(
        id: "livephone",
        apply_format?: true,
        placeholder: "Phone Number"
      )

    assert component =~ "masks=\"XXX-XXX-XXXX\""
  end

  test "support setting mask (multiple)" do
    component =
      render_live_phone(
        id: "livephone",
        apply_format?: true,
        country: "SE",
        placeholder: "Phone Number"
      )

    assert component =~
             "masks=\"X XX XX XX,XX XXX XX XX,XXX XX XX XXX,XX XX XX XX,XXX XX XXX XX XX\""
  end

  test "support setting form and field from changeset (new)" do
    use PhoenixHTMLHelpers

    changeset = LivePhoneTestApp.User.changeset()

    component =
      render_live_phone(id: "livephone", form: FormData.to_form(changeset, []), field: :phone)

    assert component =~ "name=\"user[phone]\""
    assert component =~ "value=\"\""
  end

  test "support setting form and field from changeset (edit)" do
    use PhoenixHTMLHelpers

    changeset =
      LivePhoneTestApp.User.changeset(
        %LivePhoneTestApp.User{},
        %{id: 1, phone: "+16502530000"}
      )

    component =
      render_live_phone(
        id: "livephone",
        form: FormData.to_form(changeset, []),
        field: :phone
      )

    assert component =~ "name=\"user[phone]\""
    assert component =~ "value=\"+16502530000\""
  end

  test "support setting form, field and name (name wins)" do
    component =
      render_live_phone(
        id: "livephone",
        name: :my_phone,
        form: :user,
        field: :phone
      )

    assert component =~ "name=\"my_phone\""
  end

  test "supports setting partial value" do
    component = render_live_phone(id: "livephone", value: "+1234")
    assert component =~ "value=\"+1234\""
  end

  test "supports setting preferred and opened?" do
    component = render_live_phone(id: "livephone", preferred: ["CA"], opened?: true)

    # NOTE: Separator should follow preferred list
    assert component =~
             [
               "<ul class=\"live_phone-country-list\" id=\"live_phone-country-list-livephone\" role=\"listbox\">",
               "<li aria-selected=\"true\" class=\"preferred selected live_phone-country-item\" phx-click=\"select_country\" phx-target=\"-1\" phx-value-country=\"CA\" role=\"option\">",
               "<span class=\"live_phone-country-item-flag\">🇨🇦</span>",
               "<span class=\"live_phone-country-item-name\">Canada</span>",
               "<span class=\"live_phone-country-item-code\">+1</span>",
               "</li>",
               "<li aria-disabled=\"true\" class=\"live_phone-country-separator\" role=\"separator\"></li>"
             ]
             |> Enum.join()
  end

  test "supports setting country and opened?" do
    component = render_live_phone(id: "livephone", country: "CA", opened?: true)

    # NOTE: Separator should NOT follow selected, because by default there are
    # still preferred to follow the selected before the separator is shown.
    assert component =~
             [
               "<ul class=\"live_phone-country-list\" id=\"live_phone-country-list-livephone\" role=\"listbox\">",
               "<li aria-selected=\"true\" class=\"preferred selected live_phone-country-item\" phx-click=\"select_country\" phx-target=\"-1\" phx-value-country=\"CA\" role=\"option\">",
               "<span class=\"live_phone-country-item-flag\">🇨🇦</span>",
               "<span class=\"live_phone-country-item-name\">Canada</span>",
               "<span class=\"live_phone-country-item-code\">+1</span>",
               "</li>",
               "<li aria-selected=\"false\""
             ]
             |> Enum.join()
  end

  test "supports setting country, preferred and opened?" do
    component =
      render_live_phone(
        id: "livephone",
        country: "CA",
        preferred: ["GB"],
        opened?: true
      )

    # NOTE: Separator should NOT follow selected, because by default there are
    # still preferred to follow the selected before the separator is shown.
    assert component =~
             [
               "<ul class=\"live_phone-country-list\" id=\"live_phone-country-list-livephone\" role=\"listbox\">",
               "<li aria-selected=\"true\" class=\"preferred selected live_phone-country-item\" phx-click=\"select_country\" phx-target=\"-1\" phx-value-country=\"CA\" role=\"option\">",
               "<span class=\"live_phone-country-item-flag\">🇨🇦</span>",
               "<span class=\"live_phone-country-item-name\">Canada</span>",
               "<span class=\"live_phone-country-item-code\">+1</span>",
               "</li>",
               "<li aria-selected=\"false\" class=\"preferred live_phone-country-item\" phx-click=\"select_country\" phx-target=\"-1\" phx-value-country=\"GB\" role=\"option\">",
               "<span class=\"live_phone-country-item-flag\">🇬🇧</span>",
               "<span class=\"live_phone-country-item-name\">United Kingdom of Great Britain and Northern Ireland (the)</span>",
               "<span class=\"live_phone-country-item-code\">+44</span>",
               "</li>",
               "<li aria-disabled=\"true\" class=\"live_phone-country-separator\" role=\"separator\"></li>"
             ]
             |> Enum.join()
  end

  test "button toggle country list", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    # No country list
    refute view |> element("ul.live_phone-country-list") |> has_element?()

    # Click the country button
    assert view |> element("div.live_phone-country") |> render_click()

    # Yes country list
    assert view |> element("ul.live_phone-country-list") |> has_element?()
  end

  test "select country", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    # Click the country button
    assert view |> element("div.live_phone-country") |> render_click()

    # Yes country list
    assert view |> element("ul.live_phone-country-list") |> has_element?()

    # Click Great Britain
    assert view |> element("li[phx-value-country=\"GB\"]") |> render_click()

    # Country list should close
    refute view |> element("ul.live_phone-country-list") |> has_element?()

    # Country button should now be Great Britain
    assert view |> element("span.live_phone-country-code") |> render() =~ "+44"
    assert view |> element("span.live_phone-country-flag") |> render() =~ "🇬🇧"
  end

  test "change placeholder on select country", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    # Placeholder is "Phone" by default
    assert view |> element(".live_phone-input[placeholder=Phone]") |> has_element?()

    # Click the country button
    assert view |> element("div.live_phone-country") |> render_click()

    # Yes country list
    assert view |> element("ul.live_phone-country-list") |> has_element?()

    # Click Great Britain
    assert view |> element("li[phx-value-country=\"GB\"]") |> render_click()

    # Placeholder should change to example number
    assert view |> element(".live_phone-input[placeholder='55 5555 5555']") |> has_element?()
  end

  test "change placeholder on select country (unless same country)", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    # Placeholder is "Phone" by default
    assert view |> element(".live_phone-input[placeholder=Phone]") |> has_element?()

    # Click the country button
    assert view |> element("div.live_phone-country") |> render_click()

    # Yes country list
    assert view |> element("ul.live_phone-country-list") |> has_element?()

    # Click Great Britain
    assert view |> element("li[phx-value-country=\"US\"]") |> render_click()

    # Placeholder should change to example number
    assert view |> element(".live_phone-input[placeholder=Phone]") |> has_element?()
  end

  test "close country list on input blur", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    # Click the country button
    assert view |> element("div.live_phone-country") |> render_click()

    # Yes country list
    assert view |> element("ul.live_phone-country-list") |> has_element?()

    # Blur the input field
    assert view |> element(".live_phone-input") |> render_blur()

    # Country list should close
    refute view |> element("ul.live_phone-country-list") |> has_element?()
  end

  test "process typing on keyup", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    # Type type type
    assert view |> element(".live_phone-input") |> render_keyup(%{"value" => "424242"})

    # Expected normalized value
    assert view |> element("input[type=hidden]") |> render() =~ "value=\"+1424242\""

    # Type type type
    assert view |> element(".live_phone-input") |> render_keyup(%{"value" => "+1 (650) 253-0000"})

    # Expected normalized value
    assert view |> element("input[type=hidden]") |> render() =~ "value=\"+16502530000\""
  end

  test "country should persist", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    # Set country to GB
    assert view |> element("div.live_phone-country") |> render_click()
    assert view |> element("li[phx-value-country=\"JP\"]") |> render_click()

    # Type number
    assert view |> element(".live_phone-input") |> render_keyup(%{"value" => "9020943029"})
    assert view |> element("span.live_phone-country-code") |> render() =~ "+81"
    assert view |> element("span.live_phone-country-flag") |> render() =~ "🇯🇵"
    assert view |> trigger_update()
    assert view |> element("span.live_phone-country-code") |> render() =~ "+81"
    assert view |> element("span.live_phone-country-flag") |> render() =~ "🇯🇵"
  end

  # This function is use to trigger the "update" callback on the component,
  # it just increments a test counter assign that is not used anywhere else.
  defp trigger_update(view) do
    view |> element("#test_incr") |> render_click()
  end

  defp render_live_phone(assigns) do
    LivePhone
    |> render_component(assigns)
    |> String.replace(~r/>([\s\n]+)</, "><", global: true)
  end
end
