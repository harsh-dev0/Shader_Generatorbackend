defmodule ShaderGenerator.Router do
  use Plug.Router

  require Logger

  plug(Plug.Logger)

  # Add CORS support for frontend integration
  plug(CORSPlug, origin: ["http://localhost:3000", "http://localhost:3001", "https://twotabshadergeneratorcalc.netlify.app/"])

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  post "/api/generate-shader" do
    Logger.info("Received shader generation request")

    case conn.body_params do
      %{"prompt" => prompt} when is_binary(prompt) and prompt != "" ->
        Logger.info("Processing prompt: #{prompt}")

        case ShaderGenerator.GroqClient.generate_shader(prompt) do
          {:ok, shader_code} ->
            Logger.info("Successfully generated shader code")

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{shader_code: shader_code}))

          {:error, reason} ->
            Logger.error("Failed to generate shader: #{inspect(reason)}")

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(500, Jason.encode!(%{error: "Groq API Error", details: inspect(reason)}))
        end

      _ ->
        Logger.warning("Invalid request: missing or empty prompt")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: "Invalid or missing prompt"}))
    end
  end

  # Health check endpoint
  get "/health" do
    send_resp(conn, 200, "OK")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
