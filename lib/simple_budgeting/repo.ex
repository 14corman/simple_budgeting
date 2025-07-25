defmodule SimpleBudgeting.Repo do
  use Ecto.Repo,
    otp_app: :simple_budgeting,
    adapter: Ecto.Adapters.Postgres
end
