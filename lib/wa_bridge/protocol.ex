defmodule WaBridge.Protocol do
  @moduledoc """
  WhatsApp binary node encoder/decoder placeholder.

  Outbound sending needs a full binary node encoder. This module will be
  extended once the binary node spec is implemented.
  """

  @doc "Encode an outbound text message. Returns {:ok, binary} or {:error, reason}."
  def encode_text(_to, _message) do
    {:error, :binary_node_encoder_not_implemented}
  end
end
