defmodule WaBridge.Noise do
  @moduledoc "Manages the Noise XX handshake state for WhatsApp."

  alias Noise.HandshakeState
  alias Noise.Protocol

  defstruct [:hs, :static_keypair]

  def init do
    # 1. Create the protocol definition
    proto = Protocol.from_name("Noise_XX_25519_AESGCM_SHA256")

    # 2. Generate our Static Identity (The "Device" ID)
    static_keys = Protocol.generate_keypair(proto)

    # 3. Initialize the Handshake as the initiator
    # 's' is our static keypair
    hs = HandshakeState.initialize(proto, true, <<>>, static_keys)

    %__MODULE__{
      hs: hs,
      static_keypair: static_keys
    }
  end

  def first_message(state) do
    # Advance the handshake: Write the first message (e)
    {payload, next_hs} = HandshakeState.write_message(state.hs, <<>>)

    # WhatsApp header prefix: "WA" + [6, 2]
    header = << "WA", 6, 2 >>
    {header <> payload, %{state | hs: next_hs}}
  end

  def process_server_reply(state, frame) do
    if byte_size(frame) <= 4 do
      raise MatchError, term: "short_handshake_reply: #{Base.encode16(frame)}"
    end

    # WhatsApp frames have a 4-byte header, then the Noise payload
    <<_header::binary-size(4), noise_payload::binary>> = frame

    # Read the message from the server (e, ee, s, es)
    try do
      {_payload, next_hs} = HandshakeState.read_message(state.hs, noise_payload)
        {_priv, pub} = state.static_keypair

        # A real QR string needs a 'ref' from WhatsApp.
        # For this first test, we use a timestamped ref.
        qr_ref = "1@#{:os.system_time(:millisecond)}"
        qr_string = "#{qr_ref},#{Base.encode64(pub)},#{Base.encode64(:crypto.strong_rand_bytes(16))}"

        {:ok, qr_string, %{state | hs: next_hs}}
    rescue
      exception -> {:error, exception}
    end
  end
end
