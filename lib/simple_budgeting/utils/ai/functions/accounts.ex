defmodule SimpleBudgeting.Utils.AI.Functions.Accounts do
  @moduledoc false

  import Ecto.Query, warn: false

  alias LangChain.Function
  alias LangChain.FunctionParam
  alias SimpleBudgeting.Repo

  def get_functions!() do
    [
      new_get_accounts!()
    ]
  end

  defp new_get_accounts!() do
    Function.new!(%{
      name: "get_accounts",
      display_text: "Get accounts",
      description: "Get a list of accounts",
      function: &execute_get_accounts/2
    })
  end

  defp execute_get_accounts(_arguments, _context) do
    headers = "name\tdescription\n"
    accounts =
      from(accounts in SimpleBudgeting.Schema.Account)
      |> Repo.all()
      |> Enum.map(fn account ->
        "#{account.name}\t#{account.description}"
      end)
      |> Enum.join("\n")

    {:ok, headers <> accounts}
  end
end
