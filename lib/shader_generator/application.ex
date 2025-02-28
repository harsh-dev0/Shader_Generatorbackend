defmodule ShaderGenerator.Application do
  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    port =
      case System.get_env("PORT") do
        nil -> 4000  # Default to 4000 if PORT is not set
        port_str -> String.to_integer(port_str)
      end

    children = [
      {Plug.Cowboy, scheme: :http, plug: ShaderGenerator.Router, options: [port: port]}
    ]

    Logger.info("Starting ShaderGenerator on port #{port}")

    opts = [strategy: :one_for_one, name: ShaderGenerator.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
