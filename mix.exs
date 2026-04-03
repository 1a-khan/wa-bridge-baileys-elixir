defmodule WaBridge.MixProject do
  use Mix.Project

  def project do
    [
      app: :wa_bridge,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {WaBridge.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
defp deps do
  [
    # For the API (Windmill)
    {:plug_cowboy, "~> 2.6"},
    {:jason, "~> 1.4"},

    # For the WhatsApp Connection
    {:websockex, "~> 0.4.3"},    # Standard Elixir WebSocket client
    {:protox, "~> 1.7"},         # Efficient Protobuf handling
    {:noise_protocol, "~> 0.2.0"},# Implementation of the Noise Handshake

    # For QR Code generation in your Mint terminal
    {:eqrcode, "~> 0.1.10"}
  ]
end
end
