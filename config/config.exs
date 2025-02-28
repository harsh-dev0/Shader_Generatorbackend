import Config

config :shader_generator,
  groq_api_key: System.get_env("GROQ_API_KEY")

# Optional environment-specific imports
if Mix.env() == :dev do
  import_config "dev.exs"
end

if Mix.env() == :prod do
  import_config "prod.exs"
end
