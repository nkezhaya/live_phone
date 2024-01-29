defmodule LivePhone.MixProject do
  use Mix.Project

  @source_url "https://github.com/nkezhaya/live_phone"

  def project do
    [
      app: :live_phone,
      version: "0.7.1",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  defp description do
    """
    LivePhone is a Phoenix LiveComponent for phone number input fields, with
    international support.
    """
  end

  defp package do
    [
      name: :live_phone,
      files: [
        "assets",
        "lib/live_phone.ex",
        "lib/live_phone",
        "mix.exs",
        "package.json",
        "README.md",
        "LICENSE"
      ],
      maintainers: ["Nick Kezhaya"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, ">= 0.0.0"},
      {:phoenix_html, ">= 0.0.0"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:ex_phone_number, ">= 0.0.0"},
      {:jason, ">= 0.0.0"},
      {:iso, ">= 0.0.0"},

      # Test/dev deps
      {:phoenix_ecto, "~> 4.0", only: :test},
      {:ecto, "~> 3.6", only: :test},
      {:floki, ">= 0.27.0", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},

      # Browser tests
      {:plug_cowboy, "~> 2.0", only: :test},
      {:hound, "~> 1.0", only: :test}
    ]
  end

  defp docs do
    [
      main: "LivePhone",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end
end
