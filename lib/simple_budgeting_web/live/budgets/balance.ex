defmodule SimpleBudgetingWeb.Budgets.Balance do
  @moduledoc false
  use SimpleBudgetingWeb, :live_view
  import Ecto.Query, warn: false

  @impl true
  def mount(_params, _session, socket) do
    budgets = get_budgets()
    original_percents = Enum.map(budgets, fn budget -> {budget.id, budget.percentage} end)
    amount = Money.new(0)

    socket =
      socket
      |> assign(estimated_income: amount)
      |> assign(estimated_timeframe: "monthly")
      |> assign(original_percents: original_percents)
      |> assign(estimated_monthly_income: amount)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    socket =
      socket
      |> set_assigns()

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_estimated_income", %{"estimated_income" => attrs}, socket) do
    amount = SimpleBudgeting.Utils.MoneyFunctions.parse_money_in_attrs!(attrs, "estimated_income") |> Map.get("estimated_income")
    estimated_timeframe = Map.get(attrs, "estimated_timeframe")

    socket =
      socket
      |> assign(estimated_income: amount)
      |> assign(estimated_timeframe: estimated_timeframe)
      |> set_assigns()

    {:noreply, socket}
  end

  @impl true
  def handle_event("reset_percentages", _params, socket) do
    Enum.each(socket.assigns.original_percents, fn {id, old_percent} ->
      SimpleBudgeting.Schema.Budget
      |> SimpleBudgeting.Repo.get(id)
      |> SimpleBudgeting.Schema.Budget.changeset(%{percentage: old_percent})
      |> Map.put(:action, :update)
      |> SimpleBudgeting.Repo.update!()
    end)

    {:noreply, set_assigns(socket)}
  end

  @impl true
  def handle_event("change", %{"budget_percent" => attrs}, socket) do
    %{"id" => id, "percentage" => percentage} = attrs

    budget_changeset =
      SimpleBudgeting.Repo.get(SimpleBudgeting.Schema.Budget, id)
      |> SimpleBudgeting.Schema.Budget.changeset(%{percentage: percentage})
      |> Map.put(:action, :update)

    if budget_changeset.valid? do
      _budget = SimpleBudgeting.Repo.update!(budget_changeset)

      {:noreply, set_assigns(socket)}
    else
      {:noreply, socket}
    end
  end

  defp set_assigns(socket) do
    %{
      estimated_income: estimated_income,
      estimated_timeframe: estimated_timeframe,
      original_percents: original_percents
    } = socket.assigns

    estimated_monthly_income =
      if estimated_timeframe == "monthly" do
        estimated_income
      else
        Money.divide(estimated_income, 12) |> List.first()
      end

    original_map_perc = Map.new(original_percents)

    today = Date.utc_today()
    start_date = Date.add(today, -365)
    number_of_days = Date.diff(today, start_date)
    days = Enum.reduce(-(number_of_days + 1)..0, [], & [Date.add(today, &1) | &2])
    budgets = get_budgets()
    {total_percentage, is_one_hundred} = get_and_check_perc_one_hundred(budgets)
    budgets_with_averages =
      budgets
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

        %{
          name: budget.name,
          monthly_averages: monthly_averages,
          percentage: budget.percentage,
          month_averages_over_year: month_averages_over_year,
          id: budget.id,
          original_percent: Map.get(original_map_perc, budget.id),
          description: budget.description
        }
      end)

    socket
    |> assign(budgets_with_averages: budgets_with_averages)
    |> assign(total_percentage: total_percentage)
    |> assign(is_one_hundred: is_one_hundred)
    |> assign(estimated_monthly_income: estimated_monthly_income)
  end

  defp get_budgets() do
    from(
      budgets in SimpleBudgeting.Schema.Budget,
      order_by: [asc: budgets.name],
      select: budgets,
      where: budgets.open
    )
    |> SimpleBudgeting.Repo.all()
  end

  defp get_and_check_perc_one_hundred(budgets) do
    budgets
    |> Enum.reduce(0.0, fn budget, acc -> acc + budget.percentage end)
    |> Float.round(3)
    |> is_one_hundrecd?()
  end

  defp is_one_hundrecd?(100.0), do: {100.0, true}
  defp is_one_hundrecd?(perc), do: {perc, false}
end
