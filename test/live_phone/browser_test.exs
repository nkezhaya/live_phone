defmodule LivePhone.BrowserTest do
  use ExUnit.Case, async: false
  use Wallaby.Feature

  alias Wallaby.{Element, Query}

  @moduletag :browser
  @root_path "/"

  feature "renders component with country list closed", %{session: session} do
    session = visit(session, @root_path)

    assert has?(session, Query.css("div.live_phone-country"))
    assert has?(session, Query.css("input[type=hidden]", visible: false))
    assert has?(session, Query.css("input.live_phone-input"))
    refute has?(session, Query.css("ul.live_phone-country-list"))
  end

  feature "clicking country should open list", %{session: session} do
    session =
      session
      |> visit(@root_path)

    refute has?(session, Query.css("ul.live_phone-country-list"))

    session =
      session
      |> click(Query.css("div.live_phone-country"))

    assert has?(session, Query.css("ul.live_phone-country-list"))
  end

  feature "typing with country list open should highlight first match", %{session: session} do
    session =
      session
      |> visit(@root_path)
      |> click(Query.css("div.live_phone-country"))

    session
    |> find(Query.css("ul.live_phone-country-list"))

    initial_selection =
      session
      |> find(Query.css("ul.live_phone-country-list .selected"))
      |> Element.text()

    assert initial_selection =~ "United States of America"

    session =
      session
      |> send_keys(["N", "e", "t", "h"])

    updated_selection =
      session
      |> find(Query.css("ul.live_phone-country-list .selected"))
      |> Element.text()

    assert updated_selection =~ "Netherlands (the)"
  end

  describe "formatting" do
    feature "typing a number should not get formatted", %{session: session} do
      session =
        session
        |> visit(@root_path)
        |> fill_in(Query.css("input.live_phone-input"), with: "6502530000")

      value =
        session
        |> find(Query.css("input.live_phone-input"))
        |> Element.attr("value")

      assert value == "6502530000"
    end

    feature "typing a partial number should get formatted", %{session: session} do
      session =
        session
        |> visit(@root_path <> "?format=1")
        |> fill_in(Query.css("input.live_phone-input"), with: "65025")

      value =
        session
        |> find(Query.css("input.live_phone-input"))
        |> Element.attr("value")

      assert value == "650-25"
    end

    feature "typing a number should get formatted", %{session: session} do
      session =
        session
        |> visit(@root_path <> "?format=1")
        |> fill_in(Query.css("input.live_phone-input"), with: "6502530000")

      value =
        session
        |> find(Query.css("input.live_phone-input"))
        |> Element.attr("value")

      assert value == "650-253-0000"
    end
  end
end
