defmodule SimpleBudgetingWeb.Budgets.Index do
  @moduledoc false
  use SimpleBudgetingWeb, :live_view
  import Ecto.Query, warn: false
  # import Ecto.Changeset

  alias SimpleBudgeting.Repo
  alias SimpleBudgetingWeb.Budgets.Index.Filter

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()
    start_date = Date.add(today, -365)
    number_of_days = Date.diff(today, start_date)
    days = Enum.reduce(-(number_of_days + 1)..0, [], & [Date.add(today, &1) | &2])

    day_labels = Enum.map(days, &SimpleBudgeting.Utils.DBFunctions.date_to_string/1) |> Enum.reverse()
    budgets = budgets()

    day_datasets =
        budgets
        |> Enum.map(fn budget ->
          amounts = SimpleBudgeting.Schema.Budget.get_amount_over_timeframe(budget, days)
          %{
            label: budget.name,
            data: amounts |> Enum.map(&Money.to_string(&1, symbol: false, separator: ""))
          }
        end)

    socket =
      socket
      |> assign(now: nil)
      |> assign(budgets: budgets)
      |> assign(accounts: accounts())
      |> assign(day_labels: day_labels)
      |> assign(day_datasets: day_datasets)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filter =
      Filter.changeset(%Filter{}, params)
      |> Ecto.Changeset.apply_changes()

    budget = %SimpleBudgeting.Schema.Budget{
      name: "",
      description: "",
      percentage: 0.0,
      amount: Money.new(0)
    }

    budget_changeset = SimpleBudgeting.Schema.Budget.changeset(budget)

    socket =
      socket
      |> assign(filter: filter)
      |> assign(budget_changeset: budget_changeset)
      |> set_assigns()

    {:noreply, socket}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    filter =
      %{socket.assigns.filter | page: page}
      |> Map.from_struct()

    filter =
      Filter.changeset(%Filter{}, filter)
      |> Ecto.Changeset.apply_changes()

    socket
    |> assign(filter: filter)
    |> noreply()

    # to = ~p"/budgets?#{filters}"
    # {:noreply, push_patch(socket, to: to)}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter}, socket) do
    filter =
      filter
      |> Map.put("page", 1)
      |> Map.put_new("status", nil)

    filter =
      Filter.changeset(%Filter{}, filter)
      |> Ecto.Changeset.apply_changes()

    socket
    |> assign(filter: filter)
    |> noreply()

    # to = ~p"/budgets?#{filter}"

    # {:noreply, push_patch(socket, to: to)}
  end

  @impl true
  def handle_event("change", %{"budget" => attrs}, socket) do
    money_attrs = SimpleBudgeting.Utils.MoneyFunctions.parse_money_in_attrs!(attrs, "amount")

    budget_changeset =
      %SimpleBudgeting.Schema.Budget{}
      |> SimpleBudgeting.Schema.Budget.changeset(money_attrs)
      |> Map.put(:action, :insert)

    # |> put_change(:amount, Map.get(attrs, "amount", "0.0"))

    socket =
      socket
      |> assign(budget_changeset: budget_changeset)

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"budget" => attrs}, socket) do
    money_attrs = SimpleBudgeting.Utils.MoneyFunctions.parse_money_in_attrs!(attrs, "amount")

    {amount, budget_attrs} = Map.pop!(money_attrs, "amount")

    budget_attrs = Map.put(budget_attrs, "amount", Money.new(0))

    budget_changeset =
      %SimpleBudgeting.Schema.Budget{}
      |> SimpleBudgeting.Schema.Budget.changeset(budget_attrs)
      |> Map.put(:action, :insert)

    if budget_changeset.valid? do
      SimpleBudgeting.Repo.transaction(fn ->
        budget = SimpleBudgeting.Repo.insert!(budget_changeset)

        type =
          if Money.positive?(amount) do
            "Credit"
          else
            "Debit"
          end

        {:ok, location} =
          SimpleBudgeting.Schema.Location.get_or_create_by(%{
            name: "System",
            description: "An item corresponding to system generated tasks"
          })

        {:ok, receipt_source} =
          SimpleBudgeting.Schema.ReceiptSource.get_or_create_by(%{
            name: "System",
            description: "An item corresponding to system generated tasks"
          })

        transaction_attrs =
          %{
            "description" => "Starting balance of new budget",
            "type" => type,
            "amount" => amount |> Money.abs(),
            "applied" => true,
            "date_taken" => Date.utc_today(),
            "budget_id" => budget.id,
            "location_id" => location.id,
            "receipt_source_id" => receipt_source.id
          }

        {:ok, _} =
          SimpleBudgeting.Schema.Transaction.insert_transaction(%SimpleBudgeting.Schema.Transaction{}, transaction_attrs)
      end)

      to = ~p"/budgets/balance_percent"
      {:noreply, push_navigate(socket, to: to)}
    else
      {:noreply, assign(socket, budget_changeset: budget_changeset)}
    end
  end

  defp budgets() do
    from(
      budgets in SimpleBudgeting.Schema.Budget,
      # select: budgets.name,
      order_by: [asc: budgets.name],
      distinct: true
    )
    |> Repo.all()
  end

  defp accounts() do
    from(
      accounts in SimpleBudgeting.Schema.Account,
      order_by: [asc: accounts.name],
      select: {accounts.name, accounts.id},
      distinct: true
    )
    |> Repo.all()
  end

  defp set_assigns(socket) do
    end_date =
      case Date.from_iso8601(socket.assigns.filter.end_date || "") do
        {:ok, date} -> date
        {:error, _} -> Date.utc_today()
      end

    start_date =
      case Date.from_iso8601(socket.assigns.filter.start_date || "") do
        {:ok, date} -> date
        {:error, _} -> Date.add(end_date, -365)
      end

    zoom_start = SimpleBudgeting.Utils.DBFunctions.date_to_string(start_date)
    zoom_end = SimpleBudgeting.Utils.DBFunctions.date_to_string(end_date)

    number_of_days = Date.diff(end_date, start_date)
    days = Enum.reduce(-(number_of_days + 1)..0, [], & [Date.add(end_date, &1) | &2])

    budgets_income_averages =
      socket.assigns.budgets
      |> Enum.map(fn budget ->
        monthly_averages = SimpleBudgeting.Schema.Budget.get_monthly_average_over_timeframe(budget, days, "Credit")
        month_averages_over_year =
          if Enum.empty?(monthly_averages) do
            Money.new(0)
          else
            monthly_averages
            |> Enum.map(fn {_, value} -> value end)
            |> SimpleBudgeting.Utils.MoneyFunctions.average_amounts()
          end

        {budget.name, month_averages_over_year}
      end)
      |> Map.new()

    budgets_spend_averages =
      socket.assigns.budgets
      |> Enum.map(fn budget ->
        monthly_averages = SimpleBudgeting.Schema.Budget.get_monthly_average_over_timeframe(budget, days, "Debit")
        month_averages_over_year =
          if Enum.empty?(monthly_averages) do
            Money.new(0)
          else
            monthly_averages
            |> Enum.map(fn {_, value} -> value end)
            |> SimpleBudgeting.Utils.MoneyFunctions.average_amounts()
          end

        {budget.name, month_averages_over_year}
      end)
      |> Map.new()

    queryable =
      from(
        budgets in SimpleBudgeting.Schema.Budget,
        as: :budgets,
        order_by: [asc: budgets.name],
        select: budgets
      )
      |> Filter.apply_filter(socket.assigns.filter)

    socket
    |> push_event("zoom", %{zoom_start: zoom_start, zoom_end: zoom_end})
    |> assign(queryable: queryable)
    |> assign(budgets_income_averages: budgets_income_averages)
    |> assign(budgets_spend_averages: budgets_spend_averages)
  end
end
