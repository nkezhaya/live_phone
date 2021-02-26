defmodule LivePhone.ComponentTest do
  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  use ExUnit.Case
  doctest LivePhone.Component

  @endpoint LivePhoneTestApp.Endpoint

  setup do
    [conn: Phoenix.ConnTest.build_conn()]
  end

  test "renders component" do
    component = render_component(LivePhone.Component, id: "livephone")
    assert component =~ "id=\"live_phone-livephone\""
  end

  test "support setting tabindex" do
    component = render_component(LivePhone.Component, id: "livephone", tabindex: 42)
    assert component =~ "tabindex=\"42\""
  end

  test "support setting name" do
    component = render_component(LivePhone.Component, id: "livephone", name: :phone)
    assert component =~ "name=\"phone\""
  end

  test "support setting form and field" do
    component = render_component(LivePhone.Component, id: "livephone", form: :user, field: :phone)

    assert component =~ "name=\"user[phone]\""
  end

  test "support setting placeholder" do
    component =
      render_component(LivePhone.Component, id: "livephone", placeholder: "Phone Number")

    assert component =~ "placeholder=\"Phone Number\""
  end

  test "support setting form and field from changeset (new)" do
    use Phoenix.HTML

    changeset = LivePhoneTestApp.User.changeset()

    form = form_for(changeset, "/")
    component = render_component(LivePhone.Component, id: "livephone", form: form, field: :phone)

    assert component =~ "name=\"user[phone]\""
    assert component =~ "value=\"\""
  end

  test "support setting form and field from changeset (edit)" do
    use Phoenix.HTML

    changeset =
      LivePhoneTestApp.User.changeset(
        %LivePhoneTestApp.User{},
        %{id: 1, phone: "+16502530000"}
      )

    form = form_for(changeset, "/")
    component = render_component(LivePhone.Component, id: "livephone", form: form, field: :phone)

    assert component =~ "name=\"user[phone]\""
    assert component =~ "value=\"+16502530000\""
  end

  test "support setting form, field and name (name wins)" do
    component =
      render_component(LivePhone.Component,
        id: "livephone",
        name: :my_phone,
        form: :user,
        field: :phone
      )

    assert component =~ "name=\"my_phone\""
  end

  test "supports setting value" do
    component = render_component(LivePhone.Component, id: "livephone", value: "+1234")
    assert component =~ "value=\"+1234\""
  end

  test "supports setting preferred and is_opened?" do
    component =
      render_component(LivePhone.Component, id: "livephone", preferred: ["CA"], is_opened?: true)

    # NOTE: Seperator should follow preferred list
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

  test "supports setting country and is_opened?" do
    component =
      render_component(LivePhone.Component, id: "livephone", country: "CA", is_opened?: true)

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

  test "supports setting country, preferred and is_opened?" do
    component =
      render_component(LivePhone.Component,
        id: "livephone",
        country: "CA",
        preferred: ["GB"],
        is_opened?: true
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
    assert view |> element("div.live_phone-country") |> render() =~ "🇬🇧 +44"
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
end
