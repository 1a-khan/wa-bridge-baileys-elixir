defmodule WaBridge.Constants do
  @doc "WhatsApp Web version as of early 2026"
  def wa_version, do: {2, 3000, 1015901307}

  @doc "The URL for the Multi-Device WebSocket"
  def wa_url, do: "wss://web.whatsapp.com/ws/chat"

  @doc "The Desktop User Agent"
  def user_agent, do: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

  @doc "Origin header required by WhatsApp Web"
  def origin, do: "https://web.whatsapp.com"
end
