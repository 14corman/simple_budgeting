defmodule SimpleBudgeting.Utils.AI.Functions do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  import Ecto.Query, warn: false

  alias SimpleBudgeting.Utils.AI.Functions
  alias SimpleBudgeting.Repo

  def get_functions!() do
    Functions.Transactions.get_functions!() ++
    Functions.Accounts.get_functions!() ++
    Functions.Budgets.get_functions!() ++
    Functions.Locations.get_functions!()
  end
end
