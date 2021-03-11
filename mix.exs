defmodule LivePhone.MixProject do
  use Mix.Project

  @source_url "https://github.com/whitepaperclip/live_phone"

  def project do
    [
      app: :live_phone,
      version: "0.1.1",
      elixir: "~> 1.11",
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
    LivePhone is a Phoenix LiveView component for phone number input fields,
    with international support.
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
      {:phoenix_live_view, "~> 0.15"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_ecto, "~> 4.0", only: :test},
      {:ex_phone_number, "~> 0.2.1"},
      {:jason, "~> 1.0"},
      {:ecto, "~> 3.5", only: :test},
      {:iso, "~> 1.0"},
      {:floki, ">= 0.27.0", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
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
