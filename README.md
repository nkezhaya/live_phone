[![Actions Status](https://github.com/nkezhaya/live_phone/actions/workflows/elixir.yml/badge.svg)](https://github.com/nkezhaya/live_phone/actions/workflows/elixir.yml?query=workflow%3ACI)
[![hex.pm](https://img.shields.io/hexpm/v/live_phone.svg)](https://hexdocs.pm/live_phone/LivePhone.html)

# LivePhone

A Phoenix LiveComponent for phone number input fields, inspired by [`intl-tel-input`](https://github.com/jackocnr/intl-tel-input).

Based on [`ISO`](https://github.com/nkezhaya/iso) and [`ex_phone_number`](https://github.com/socialpaymentsbv/ex_phone_number), which in turn is based on [libphonenumber](https://github.com/google/libphonenumber).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `live_phone` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:live_phone, "~> 0.10"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/live_phone](https://hexdocs.pm/live_phone).

To your `assets/package.json` file add:
```
"live_phone": "file:../deps/live_phone",
```

To your `app.js` add something like:
```
import LivePhone from "live_phone"
let Hooks = {}
Hooks.LivePhone = LivePhone
```

And finally to your CSS add:
```
@import "../../deps/live_phone/assets/live_phone";
```

## Usage

Usage is pretty simple, and there is an example Phoenix project included in the `./example` directory of this repository.

```elixir
<.live_component
  module={LivePhone}
  id="phone"
  form={:user}
  field={:phone}
  tabindex={0}
  preferred={["US", "CA"]}
  phx_debounce="100" />
```

This will result in a form field with the name `user[phone]`. You can specify just the `name` manually if desired, but when you add the `form` option the name will be generated via `Phoenix.HTML.Form.input_name/2`. So this should behave like a regular input field.

With `preferred` you can set a list of countries that you believe should be on top always. The currently selected country will also be on top automatically.

With `phx_debounce`, you can rate limit events affecting the input field, so that you won't send events to your backend everytime the user presses a key stroke. Please refer [https://hexdocs.pm/phoenix_live_view/bindings.html#rate-limiting-events-with-debounce-and-throttle](to your version of LiveView bindings for more information). Sending too many events to your backend may make your UI erratic and slow to respond to users with a lot of latency.

## Example

In the `example/` directory you will find a minimal Phoenix application to demonstrate `LivePhone` in usage.

## Browser Tests (Wallaby)

To run the browser tests you need to install `chromedriver` (`brew install chromedriver` on macOS) so Wallaby can launch headless Chrome. The tests are excluded by default; include them with `--include browser` when running `mix test`.

An "invalid session id" error can usually be fixed by upgrading chromedriver.
