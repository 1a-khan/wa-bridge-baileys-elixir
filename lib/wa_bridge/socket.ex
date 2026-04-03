defmodule WaBridge.Socket do
  use WebSockex
  import Bitwise
  require Logger
  alias WaBridge.Constants
  alias WaBridge.Noise
  alias WaBridge.Protocol
  alias WaBridge.Session

  def start_link(_) do
    url = Constants.wa_url()
    state = %{
      noise: Noise.init(),
      is_connected: false,
      paired: false
    }

    WebSockex.start_link(url, __MODULE__, state, [
      # WhatsApp is strict about the User-Agent
      extra_headers: [
        {"User-Agent", Constants.user_agent()},
        {"Origin", Constants.origin()}
      ],
      name: __MODULE__,
      debug: [:trace]
    ])
  end

  @impl true
  def handle_connect(_conn, state) do
    Logger.info("WebSocket Connected. Initializing Handshake...")
    send(self(), :send_handshake)
    {:ok, state}
  end

  @impl true
  def handle_disconnect(connection_status_map, state) do
    Logger.error("WebSocket disconnected: #{inspect(connection_status_map)}")
    Session.set_error("ws_disconnect: #{inspect(connection_status_map)}")
    {:ok, state}
  end

  @impl true
  def handle_info(:send_handshake, state) do
    Logger.info("Sending Handshake payload...")
    {payload, new_noise} = Noise.first_message(state.noise)
    {:reply, {:binary, payload}, %{state | noise: new_noise}}
  end

  @impl true
  def handle_frame({:binary, frame}, state) do
    case frame do
      <<0x88, 0x02, c1, c2>> ->
        code = (c1 <<< 8) + c2
        Logger.error("Received close frame as binary: code=#{code}")
        Session.set_error("ws_close_binary: #{code}")
        {:ok, state}

      _ ->
    Logger.info("Received binary frame of size: #{byte_size(frame)}. Processing...")

    # Here we use the function from our Noise module to finish the handshake
    case Noise.process_server_reply(state.noise, frame) do
      {:ok, qr_string, new_noise} ->
        # 1. Generate the QR Code matrix
        qr_matrix = EQRCode.encode(qr_string)

        # 2. Render it to your Mint terminal
        IO.puts("\n--- SCAN THIS WITH WHATSAPP ---\n")
        EQRCode.render(qr_matrix) |> IO.puts()
        IO.puts("\n-------------------------------\n")

        Session.put_qr(qr_string)
        Session.set_paired(false)

        {:ok, %{state | noise: new_noise, is_connected: true, paired: false}}

      {:error, reason} ->
        Logger.error("Handshake failed: #{inspect(reason)}")
        Session.set_error("handshake_failed: #{inspect(reason)}")
        {:ok, state}
    end
    end
  end

  # We should also handle text frames just in case WhatsApp sends a 'ping'
  @impl true
  def handle_frame({:text, msg}, state) do
    Logger.debug("Received text frame: #{msg}")
    {:ok, state}
  end

  @impl true
  def handle_frame({:close, code, reason}, state) do
    Logger.error("WebSocket close frame: code=#{inspect(code)} reason=#{inspect(reason)}")
    Session.set_error("ws_close: #{inspect(code)} #{inspect(reason)}")
    {:ok, state}
  end

  @impl true
  def handle_cast({:send_message, to, message}, state) do
    if state.paired do
      case Protocol.encode_text(to, message) do
        {:ok, payload} ->
          {:reply, {:binary, payload}, state}

        {:error, reason} ->
          Logger.error("Encode failed: #{inspect(reason)}")
          Session.set_error("encode_failed: #{inspect(reason)}")
          {:ok, state}
      end
    else
      Session.set_error("not_paired")
      {:ok, state}
    end
  end

  def send_message(to, message) do
    %{paired: paired} = Session.status()

    if paired do
      WebSockex.cast(__MODULE__, {:send_message, to, message})
      :ok
    else
      {:error, :not_paired}
    end
  end
end
