defmodule LivePhone.BrowserTest do
  use ExUnit.Case
  use Hound.Helpers

  @moduletag :browser
  @endpoint "http://localhost:4002/"

  hound_session(additional_capabilities: %{browserName: "chrome"})

  describe "country list" do
    test "renders component with country list closed" do
      navigate_to(@endpoint)
      _country_selector = find_element(:css, "div.live_phone-country")
      _hidden_input = find_element(:css, "input[type=hidden]")
      _text_input = find_element(:css, "input.live_phone-input")
      assert [] = find_all_elements(:css, "ul.live_phone-country-list")
    end

    test "clicking country should open list" do
      navigate_to(@endpoint)
      country_selector = find_element(:css, "div.live_phone-country")
      assert [] == find_all_elements(:css, "ul.live_phone-country-list")
      click(country_selector)
      _country_list = find_element(:css, "ul.live_phone-country-list")
    end

    test "typing with country list open should highlight first match" do
      navigate_to(@endpoint)
      country_selector = find_element(:css, "div.live_phone-country")
      click(country_selector)
      find_element(:css, "ul.live_phone-country-list")

      item = find_element(:css, "ul.live_phone-country-list .selected")
      assert visible_text(item) =~ "United States of America"

      send_text("Neth")

      item = find_element(:css, "ul.live_phone-country-list .selected")
      assert visible_text(item) =~ "Netherlands (the)"
    end
  end

  describe "formatting" do
    test "typing a number should not get formatted" do
      navigate_to(@endpoint)
      text_input = find_element(:css, "input.live_phone-input")
      input_into_field(text_input, "6502530000")
      assert attribute_value(text_input, "value") == "6502530000"
    end

    test "typing a partial number should get formatted" do
      navigate_to(@endpoint <> "?format=1")
      text_input = find_element(:css, "input.live_phone-input")
      input_into_field(text_input, "65025")
      assert attribute_value(text_input, "value") == "650-25"
    end

    test "typing a number should get formatted" do
      navigate_to(@endpoint <> "?format=1")
      text_input = find_element(:css, "input.live_phone-input")
      input_into_field(text_input, "6502530000")
      assert attribute_value(text_input, "value") == "650-253-0000"
    end
  end
end
