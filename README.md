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
    {:live_phone, "~> 0.7"}
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
  preferred={["US", "CA"]} />
```

This will result in a form field with the name `user[phone]`. You can specify just the `name` manually if desired, but when you add the `form` option the name will be generated via `Phoenix.HTML.Form.input_name/2`. So this should behave like a regular input field.

With `preferred` you can set a list of countries that you believe should be on top always. The currently selected country will also be on top automatically.

## Example

In the `example/` directory you will find a minimal Phoenix application to demonstrate `LivePhone` in usage.

## Browser Tests (chromedriver)

To run the browser tests you need to install `chromedriver` (`brew install chromedriver` on MacOS) and it has to be running already. The tests are excluded by default, but you can include them with `--include browser`. See below:

An "invalid session id" error can usually be fixed by upgrading chromedriver.

```
$ chromedriver --verbose --url-base=/wd/hub # hound assumes default port 9515)
$ mix test --include browser
```
