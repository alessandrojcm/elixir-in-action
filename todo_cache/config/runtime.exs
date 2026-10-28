import Config

http_port =
  if(config_env() != :test, System.get_env("TODO_HTTP_PORT", "5454"),
    else: System.get_env("TODO_HTTP_PORT", "5455")
  )

config :todo, http_port: String.to_integer(http_port)
