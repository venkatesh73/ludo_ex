defmodule LudoEx.Repo do
  use Ecto.Repo,
    otp_app: :ludo_ex,
    adapter: Ecto.Adapters.Postgres
end
