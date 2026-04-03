defmodule WaBridge.Baileys do
  @moduledoc """
  Bridge to a Node.js Baileys process.
  """

  use GenServer
  require Logger

  @type state :: %{
          port: port() | nil,
          started: boolean()
        }

  # Public API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def ensure_started do
    GenServer.cast(__MODULE__, :ensure_started)
  end

  def send_message(to, message) when is_binary(to) and is_binary(message) do
    ensure_started()
    GenServer.cast(__MODULE__, {:send_message, to, message})
  end

  # GenServer

  @impl true
  def init(_) do
    {:ok, %{port: nil, started: false}}
  end

  @impl true
  def handle_cast(:ensure_started, %{started: true} = state) do
    {:noreply, state}
  end

  def handle_cast(:ensure_started, %{started: false} = state) do
    {:noreply, %{state | port: start_port(), started: true}}
  end

  @impl true
  def handle_cast({:send_message, to, message}, %{port: port} = state) when is_port(port) do
    payload = Jason.encode!(%{type: "send", to: to, message: message})
    Port.command(port, payload <> "\n")
    {:noreply, state}
  end

  def handle_cast({:send_message, _to, _message}, state) do
    WaBridge.Session.set_error("baileys_not_started")
    {:noreply, state}
  end

  @impl true
  def handle_info({port, {:data, {:eol, data}}}, %{port: port} = state) do
    data
    |> String.trim()
    |> decode_message()
    |> handle_event()

    {:noreply, state}
  end

  def handle_info({port, {:data, data}}, %{port: port} = state) when is_binary(data) do
    data
    |> String.trim()
    |> decode_message()
    |> handle_event()

    {:noreply, state}
  end

  @impl true
  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    Logger.error("Baileys port exited with status #{status}")
    WaBridge.Session.set_error("baileys_port_exit: #{status}")
    Process.send_after(self(), :restart_port, 1_000)
    {:noreply, %{state | port: nil, started: false}}
  end

  @impl true
  def handle_info(:restart_port, state) do
    {:noreply, %{state | port: start_port(), started: true}}
  end

  defp start_port do
    node = System.find_executable("node") || "node"
    script = Path.expand("node/baileys_bridge.mjs", File.cwd!())
    auth_dir = Path.expand("node/baileys_auth", File.cwd!())

    File.mkdir_p!(auth_dir)

    Port.open(
      {:spawn_executable, node},
      [
        :binary,
        :exit_status,
        :line,
        args: [script, auth_dir]
      ]
    )
  end

  defp decode_message(""), do: :ignore

  defp decode_message(data) do
    case Jason.decode(data) do
      {:ok, msg} -> msg
      _ -> {:invalid, data}
    end
  end

  defp handle_event(:ignore), do: :ok

  defp handle_event(%{"type" => "qr", "qr" => qr}) do
    WaBridge.Session.put_qr(qr)
    WaBridge.Session.set_paired(false)

    qr
    |> EQRCode.encode()
    |> render_small()
    |> then(&IO.puts("\n--- SCAN THIS WITH WHATSAPP ---\n#{&1}\n-------------------------------\n"))
  end

  defp handle_event(%{"type" => "paired"}) do
    WaBridge.Session.set_paired(true)
  end

  defp handle_event(%{"type" => "close", "reason" => reason}) do
    WaBridge.Session.set_error("baileys_close: #{reason}")
  end

  defp handle_event(%{"type" => "error", "error" => error}) do
    WaBridge.Session.set_error("baileys_error: #{error}")
  end

  defp handle_event({:invalid, data}) do
    Logger.error("Invalid JSON from Baileys: #{inspect(data)}")
  end

  defp handle_event(_), do: :ok

  defp render_small(%EQRCode.Matrix{matrix: matrix}) do
    matrix
    |> tuple_to_list()
    |> Enum.map(fn row ->
      row
      |> tuple_to_list()
      |> Enum.map(fn
        1 -> "#"
        _ -> " "
      end)
      |> Enum.join()
    end)
    |> Enum.join("\n")
  end

  defp tuple_to_list(value) when is_tuple(value), do: Tuple.to_list(value)
  defp tuple_to_list(value) when is_list(value), do: value
  defp tuple_to_list(other), do: [other]
end
