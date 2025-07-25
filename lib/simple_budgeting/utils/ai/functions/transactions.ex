defmodule SimpleBudgeting.Utils.AI.Functions.Transactions do
  @moduledoc false

  import Ecto.Query, warn: false

  alias LangChain.Function
  alias LangChain.FunctionParam
  alias SimpleBudgeting.Repo

  def get_functions!() do
    [
      new_get_transactions_filters!()
    ]
  end

  defp new_get_transactions_filters!() do
    Function.new!(%{
      name: "get_transactions_filters",
      display_text: "Query transactions",
      description: "Get a list of transactions for a given optional budget, start date, and end date",
      parameters: [
        FunctionParam.new!(%{
          name: "budget_name",
          type: :string,
          description: "Optional: The name of the budget to get transactions for."
        }),
        FunctionParam.new!(%{
          name: "start_date",
          type: :string,
          description: "The optional date to start looking at. Must be in the form yyy-mm-dd."
        }),
        FunctionParam.new!(%{
          name: "end_date",
          type: :string,
          description: "The optional date to end looking at. Must be in the form yyy-mm-dd. Defaults to today."
        })
      ],
      function: &execute_get_transactions_filters/2
    })
  end

  defp execute_get_transactions_filters(arguments, context) do
    end_date =
      case Map.get(arguments, "end_date") do
        nil -> context.today
        "" -> context.today
        end_date -> Date.from_iso8601!(end_date)
      end

    start_date =
      case Map.get(arguments, "start_date") do
        nil -> ~D[1900-01-01]
        "" -> ~D[1900-01-01]
        start_date -> Date.from_iso8601!(start_date)
      end

    headers = "description\ttype\tamount\tapplied\tdate_taken\n"
    queryable =
      from(
        transactions in SimpleBudgeting.Schema.Transaction,
        inner_join: budgets in assoc(transactions, :budget), as: :budgets,
        where: transactions.date_taken >= ^start_date and transactions.date_taken <= ^end_date
      )

    queryable =
      case Map.get(arguments, "budget_name") do
        nil -> queryable
        "" -> queryable
        budget_name -> where(queryable, [budgets: budgets], budgets.name == ^budget_name)
      end

    transactions =
      queryable
      |> Repo.all()
      |> Enum.map(fn transaction ->
        "#{transaction.description}\t#{transaction.type}\t#{Money.to_string(transaction.amount)}\t#{transaction.applied}\t#{Date.to_iso8601(transaction.date_taken)}"
      end)
      |> Enum.join("\n")

    {:ok, headers <> transactions}
  end
end
