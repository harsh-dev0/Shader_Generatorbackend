import Config

config :your_app, YourApp.Repo,
  port: String.to_integer(System.get_env("PORT") || "4000")
