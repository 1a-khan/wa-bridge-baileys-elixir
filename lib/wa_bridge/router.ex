defmodule WaBridge.Router do
  use Plug.Router
  require Logger

  plug Plug.Logger
  plug :match

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason

  plug :dispatch

  get "/status" do
    Logger.info("GET /status")
    status = WaBridge.Session.status()
    send_resp(conn, 200, Jason.encode!(status))
  end

  get "/qr" do
    Logger.info("GET /qr")
    WaBridge.Baileys.ensure_started()
    %{qr: qr} = WaBridge.Session.status()

    if is_binary(qr) do
      send_resp(conn, 200, Jason.encode!(%{qr: qr}))
    else
      send_resp(conn, 404, Jason.encode!(%{error: "qr_not_ready"}))
    end
  end

  get "/qr.png" do
    Logger.info("GET /qr.png")
    WaBridge.Baileys.ensure_started()
    %{qr: qr} = WaBridge.Session.status()

    if is_binary(qr) do
      png =
        qr
        |> EQRCode.encode()
        |> EQRCode.png(width: 640)

      conn
      |> Plug.Conn.put_resp_content_type("image/png")
      |> send_resp(200, png)
    else
      send_resp(conn, 404, Jason.encode!(%{error: "qr_not_ready"}))
    end
  end

  post "/send" do
    Logger.info("POST /send body=#{inspect(conn.body_params)}")
    with %{"to" => to, "message" => message} <- conn.body_params,
         true <- is_binary(to) and byte_size(to) > 0,
         true <- is_binary(message) and byte_size(message) > 0 do
      WaBridge.Baileys.send_message(to, message)
      send_resp(conn, 200, Jason.encode!(%{status: "queued"}))
    else
      _ ->
        send_resp(conn, 400, Jason.encode!(%{error: "invalid_payload"}))
    end
  end

  match _ do
    send_resp(conn, 404, Jason.encode!(%{error: "not_found"}))
  end
end
