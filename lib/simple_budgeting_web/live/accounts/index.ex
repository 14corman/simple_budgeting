defmodule SimpleBudgetingWeb.Accounts.Index do
  @moduledoc false
  use SimpleBudgetingWeb, :live_view
  import Ecto.Query, warn: false

  alias SimpleBudgetingWeb.Accounts.Filter

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()
    start_date = Date.add(today, -365)
    number_of_days = Date.diff(today, start_date)
    days = Enum.reduce(-(number_of_days + 1)..0, [], & [Date.add(today, &1) | &2])

    day_labels = Enum.map(days, &SimpleBudgeting.Utils.DBFunctions.date_to_string/1) |> Enum.reverse()
    accounts = accounts()
    day_datasets =
      accounts
      |> Enum.map(fn account ->
        amounts = SimpleBudgeting.Schema.Account.get_amount_over_timeframe(account, days)
        %{
          label: account.name,
          data: amounts |> Enum.map(&Money.to_string(&1, symbol: false, separator: ""))
        }
      end)

    socket =
      socket
      |> assign(now: nil)
      |> assign(day_labels: day_labels)
      |> assign(day_datasets: day_datasets)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filter =
      Filter.changeset(%Filter{}, params)
      |> Ecto.Changeset.apply_changes()

    account = %SimpleBudgeting.Schema.Account{
      name: "",
      description: ""
    }

    account_changeset = SimpleBudgeting.Schema.Account.changeset(account)

    socket =
      socket
      |> assign(filter: filter)
      |> assign(account_changeset: account_changeset)
      |> set_assigns()

    {:noreply, socket}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    filters =
      %{socket.assigns.filter | page: page}
      |> Map.from_struct()

    to = ~p"/accounts?#{filters}"
    {:noreply, push_patch(socket, to: to)}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter}, socket) do
    filter =
      filter
      |> Map.put("page", 1)

    to = ~p"/accounts?#{filter}"
    {:noreply, push_patch(socket, to: to)}
  end

  @impl true
  def handle_event("change", %{"account" => attrs}, socket) do
    account_changeset =
      %SimpleBudgeting.Schema.Account{}
      |> SimpleBudgeting.Schema.Account.changeset(attrs)
      |> Map.put(:action, :insert)

    socket =
      socket
      |> assign(account_changeset: account_changeset)

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"account" => attrs}, socket) do
    account_changeset =
      %SimpleBudgeting.Schema.Account{}
      |> SimpleBudgeting.Schema.Account.changeset(attrs)
      |> Map.put(:action, :insert)

    if account_changeset.valid? do
      _account = SimpleBudgeting.Repo.insert!(account_changeset)

      to = ~p"/accounts"
      {:noreply, push_navigate(socket, to: to)}
    else
      {:noreply, assign(socket, account_changeset: account_changeset)}
    end
  end

  defp set_assigns(socket) do
    queryable =
      from(
        accounts in SimpleBudgeting.Schema.Account,
        as: :accounts,
        order_by: [asc: accounts.name],
        select: accounts
      )
      |> Filter.apply_filter(socket.assigns.filter)

    total =
      queryable
      |> SimpleBudgeting.Repo.all()
      |> SimpleBudgeting.Repo.preload(:budgets)
      |> Enum.flat_map(& &1.budgets)
      |> Enum.uniq()
      |> calc_total_amount()

    socket
    |> assign(queryable: queryable)
    |> assign(total: total)
  end

  defp accounts() do
    from(
      accounts in SimpleBudgeting.Schema.Account,
      order_by: [asc: accounts.name],
      distinct: true
    )
    |> SimpleBudgeting.Repo.all()
  end

  defp calc_total_amount(budgets) do
    budgets
    |> Enum.reduce(Money.new(0), fn budget, acc -> Money.add(budget.amount, acc) end)
  end
end
