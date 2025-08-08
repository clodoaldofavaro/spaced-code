import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :leetcode_spaced, LeetcodeSpaced.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "leetcode_spaced_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :leetcode_spaced, LeetcodeSpacedWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "mhF0+JC6HjbzFUzN1Kj2AKERXDv2/Crb1TL2fpxcsO6US/TcE29sLvszaE2CvQUa",
  server: false

# In test we don't send emails
config :leetcode_spaced, LeetcodeSpaced.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
