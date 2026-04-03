defmodule WaBridge.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port =
      System.get_env("PORT", "4001")
      |> String.to_integer()

    children = [
      WaBridge.Session,
      WaBridge.Baileys,
      {Plug.Cowboy,
       scheme: :http,
       plug: WaBridge.Router,
       options: [port: port, ip: {0, 0, 0, 0}]}
      # Starts a worker by calling: WaBridge.Worker.start_link(arg)
      # {WaBridge.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WaBridge.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
