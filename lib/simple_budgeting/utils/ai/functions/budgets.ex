defmodule SimpleBudgeting.Utils.AI.Functions.Budgets do
  @moduledoc false

  import Ecto.Query, warn: false

  alias LangChain.Function
  alias LangChain.FunctionParam
  alias SimpleBudgeting.Repo

  def get_functions!() do
    [
      new_get_budgets!(),
      new_get_budget_amount!()
    ]
  end

  defp new_get_budgets!() do
    Function.new!(%{
      name: "get_budgets",
      display_text: "Get budgets",
      description: "Get a list of budgets",
      function: &execute_get_budgets/2
    })
  end

  defp new_get_budget_amount!() do
    Function.new!(%{
      name: "get_budget_amount",
      display_text: "Get current budget amount",
      description: "Get the current amount of a budget",
      parameters: [
        FunctionParam.new!(%{
          name: "budget_name",
          type: :string,
          description: "The name of the budget to get the current amount of.",
          required: true
        }),
      ],
      function: &execute_get_budget_amount/2
    })
  end

  defp execute_get_budgets(_arguments, _context) do
    headers = "name\tdescription\tpercentage\tamount\topen\tclosed_on\n"

    budgets =
      from(budgets in SimpleBudgeting.Schema.Budget)
      |> Repo.all()
      |> Enum.map(fn budgets ->
        "#{budgets.name}\t#{budgets.description}\t#{budgets.percentage}\t#{budgets.amount}\t#{budgets.open}\t#{Date.to_iso8601(budgets.closed_on)}"
      end)
      |> Enum.join("\n")

    {:ok, headers <> budgets}
  end

  defp execute_get_budget_amount(%{"budget_name" => budget_name} = _arguments, _context) do
    amount =
      from(budgets in SimpleBudgeting.Schema.Budget, where: budgets.name == ^budget_name, limit: 1)
      |> Repo.one()
      |> case do
        nil -> "Name given does not match a budget"
        budget -> Money.to_string(budget.amount)
      end

    {:ok, amount}
  end
end
