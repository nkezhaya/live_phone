# LivePhone

A Phoenix LiveView Component for phone number input fields, basically a [`intl-tel-input` ](https://github.com/jackocnr/intl-tel-input) for Phoenix LiveView.

Based on [`ISO`](https://github.com/whitepaperclip/iso) and [`ex_phone_number`](https://github.com/socialpaymentsbv/ex_phone_number), which in turn is based on [libphonenumber](https://github.com/google/libphonenumber).


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `live_phone` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:live_phone, "~> 0.3"}
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


## Example

In the `example/` directory you will find a very minimal Phoenix application to demonstrate `LivePhone` in usage.

## Browser Tests (chromedriver)
To run the browser tests you need to install `chromedriver` (`brew install chromedriver` on MacOS) and it has to be running already. The tests are excluded by default, but you can include them with `--include browser`. See below:

```
$ chromedriver # hound assumes default port 9515)
$ mix test --include browser
```
