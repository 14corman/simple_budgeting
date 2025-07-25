defmodule SimpleBudgetingWeb.Index do
  @moduledoc false
  use SimpleBudgetingWeb, :live_view
  import Ecto.Query, warn: false

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(show_pie_chart: true)
      |> set_assigns()

    {:ok, socket}
  end

  # @impl true
  # def handle_event("toggle_main_chart_type", _params, socket) do
  #   socket =
  #     socket
  #     |> assign(show_pie_chart: !socket.assigns.show_pie_chart)
  #     |> set_assigns()

  #   {:noreply, socket}
  # end

  defp set_assigns(socket) do
    budget_amounts =
      from(
        budgets in SimpleBudgeting.Schema.Budget,
        where: budgets.open,
        order_by: [asc: budgets.name],
        select: %{
          label: budgets.name,
          value: budgets.amount
        }
      )
      |> SimpleBudgeting.Repo.all()
      |> Enum.map(&parse_budget_money(&1, false))
      |> Enum.filter(fn %{value: amount} -> !(false && amount == 0.0) end)

    account_amounts =
      from(
        accounts in SimpleBudgeting.Schema.Account,
        join: budgets in assoc(accounts, :budgets),
        where: budgets.open,
        order_by: [asc: accounts.name],
        group_by: accounts.name,
        select: %{
          label: accounts.name,
          value: fragment("array_agg(?)", budgets.amount)
        }
      )
      |> SimpleBudgeting.Repo.all()
      |> Enum.map(&parse_account_money(&1, false))
      |> Enum.filter(fn %{value: amount} -> !(false && amount == 0.0) end)

    account_dataset = [%{
      label: "",
      data: Enum.map(account_amounts, & &1.value)
    }]

    budget_dataset = [%{
      label: "",
      data: Enum.map(budget_amounts, & &1.value)
    }]

    today = Date.utc_today()
    start_date = Date.add(today, -365)
    number_of_days = Date.diff(today, start_date)
    days = Enum.reduce(-(number_of_days + 1)..0, [], & [Date.add(today, &1) | &2])

    day_labels = Enum.map(days, &SimpleBudgeting.Utils.DBFunctions.date_to_string/1) |> Enum.reverse()
    accounts = accounts()
    day_datasets =
      accounts
      |> Enum.reduce(nil, fn account, total_amounts ->
        amounts = SimpleBudgeting.Schema.Account.get_amount_over_timeframe(account, days)
        if total_amounts do
          total_amounts
          |> Enum.zip(amounts)
          |> Enum.map(fn {a1, a2} -> Money.add(a1, a2) end)
        else
          amounts
        end
      end)
      |> then(fn amounts ->
        [%{
          label: "Total",
          data: amounts |> Enum.map(&Money.to_string(&1, symbol: false, separator: ""))
        }]
      end)

    total =
      accounts
      |> SimpleBudgeting.Repo.preload(:budgets)
      |> Enum.flat_map(& &1.budgets)
      |> Enum.uniq()
      |> Enum.reduce(Money.new(0), fn budget, acc -> Money.add(budget.amount, acc) end)

    socket
    |> assign(budget_labels: Enum.map(budget_amounts, & &1.label))
    |> assign(budget_dataset: budget_dataset)
    |> assign(account_labels: Enum.map(account_amounts, & &1.label))
    |> assign(account_dataset: account_dataset)
    |> assign(day_labels: day_labels)
    |> assign(day_datasets: day_datasets)
    |> assign(total: total)
  end

  defp parse_account_money(%{label: name, value: budgets}, show_pie_chart) do
    amount =
      budgets
      |> Enum.map(fn %{"amount" => amount, "currency" => currency} ->
        Money.new(amount, currency)
      end)
      |> Enum.reduce(Money.new(0), fn amount, acc -> Money.add(amount, acc) end)
      |> check_if_neg_and_pie_chart(show_pie_chart)

    money_float = SimpleBudgeting.Utils.MoneyFunctions.money_to_float(amount)

    %{label: name, value: money_float, amount_string: Money.to_string(amount)}
  end

  defp parse_budget_money(%{label: name, value: amount}, show_pie_chart) do
    amount =
      amount
      |> check_if_neg_and_pie_chart(show_pie_chart)

    money_float = SimpleBudgeting.Utils.MoneyFunctions.money_to_float(amount)

    %{label: name, value: money_float, amount_string: Money.to_string(amount)}
  end

  defp check_if_neg_and_pie_chart(money, show_pie_chart) do
    if Money.negative?(money) && show_pie_chart do
      Money.new(0)
    else
      money
    end
  end

  defp accounts() do
    from(
      accounts in SimpleBudgeting.Schema.Account,
      distinct: true
    )
    |> SimpleBudgeting.Repo.all()
  end
end
