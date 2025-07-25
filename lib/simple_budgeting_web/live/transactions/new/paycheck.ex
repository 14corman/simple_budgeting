defmodule SimpleBudgetingWeb.Transactions.New.Paycheck do
  @moduledoc false
  use SimpleBudgetingWeb, :live_view

  import Ecto.Query, warn: false

  alias SimpleBudgeting.Schema.Transaction
  alias SimpleBudgetingWeb.Transactions.Filter
  alias SimpleBudgetingWeb.Transactions.New.Paycheck.Form, as: PaycheckForm

  @impl true
  def mount(_params, _uri, socket) do
    receipt_sources =
      from(
        receipt_sources in SimpleBudgeting.Schema.ReceiptSource,
        order_by: receipt_sources.name,
        where: receipt_sources.name != "System",
        select: {receipt_sources.name, receipt_sources.id}
      )
      |> SimpleBudgeting.Repo.all()

    budgets =
      from(
        budgets in SimpleBudgeting.Schema.Budget,
        order_by: budgets.name,
        where: budgets.open
      )
      |> SimpleBudgeting.Repo.all()

    budget_selection = Enum.map(budgets, &{&1.name, &1.id})

    locations =
      from(
        locations in SimpleBudgeting.Schema.Location,
        order_by: locations.name,
        select: locations.name
      )
      |> SimpleBudgeting.Repo.all()

    changeset = PaycheckForm.changeset(%PaycheckForm{date_taken: Date.utc_today()}, %{})
    budget_amounts = Enum.map(budgets, fn _ -> Money.new(0) end)

    socket =
      socket
      |> assign(changeset: changeset)
      |> assign(receipt_sources: receipt_sources)
      |> assign(budgets: budgets)
      |> assign(budget_selection: budget_selection)
      |> assign(locations: locations)
      |> assign(budget_amounts: budget_amounts)
      |> assign(leftover: Money.new(0))
      |> assign(location_name: nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filter_map =
      Filter.changeset(%Filter{}, params)
      |> Ecto.Changeset.apply_changes()
      |> Map.from_struct()

    socket =
      socket
      |> assign(filter_map: filter_map)

    {:noreply, socket}
  end

  @impl true
  def handle_event("change", %{"form" => attrs}, socket) do
    money_attrs = SimpleBudgeting.Utils.MoneyFunctions.parse_money_in_attrs!(attrs, "paycheck_amount")

    %{"paycheck_amount" => paycheck_amount} = money_attrs

    {location_name, money_attrs} = get_location_name(money_attrs)

    changeset =
      PaycheckForm.changeset(%PaycheckForm{date_taken: Date.utc_today()}, money_attrs)
      |> Map.put(:action, :insert)

    budget_amounts = get_budget_amounts_by_percents(socket.assigns.budgets, paycheck_amount)

    leftover_amount =
      budget_amounts
      |> Enum.reduce(Money.new(0), fn amount, acc -> Money.add(amount, acc) end)
      |> Money.subtract(paycheck_amount)
      |> Money.multiply(-1)

    socket =
      socket
      |> assign(changeset: changeset)
      |> assign(budget_amounts: budget_amounts)
      |> assign(leftover: leftover_amount)
      |> assign(location_name: location_name)

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"form" => attrs}, socket) do
    money_attrs = SimpleBudgeting.Utils.MoneyFunctions.parse_money_in_attrs!(attrs, "paycheck_amount")
    %{"paycheck_amount" => paycheck_amount} = money_attrs
    {_location_name, money_attrs} = get_location_name(money_attrs)

    changeset =
      PaycheckForm.changeset(%PaycheckForm{date_taken: Date.utc_today()}, money_attrs)
      |> Map.put(:action, :insert)

    budget_amounts = get_budget_amounts_by_percents(socket.assigns.budgets, paycheck_amount)

    leftover_amount =
      budget_amounts
      |> Enum.reduce(Money.new(0), fn amount, acc -> Money.add(amount, acc) end)
      |> Money.subtract(paycheck_amount)
      |> Money.multiply(-1)

    leftover_budget =
      SimpleBudgeting.Schema.Budget
      |> SimpleBudgeting.Repo.get(money_attrs["leftover_budget_id"])
      |> case do
        nil -> List.first(socket.assigns.budgets)
        budget -> budget
      end

    if changeset.valid? do
      SimpleBudgeting.Repo.transaction(fn ->
        receipt_source_transaction =
          %SimpleBudgeting.Schema.ReceiptSource.Transaction{}
          |> SimpleBudgeting.Schema.ReceiptSource.Transaction.changeset(money_attrs)
          |> SimpleBudgeting.Repo.insert!()

        [budget_amounts, socket.assigns.budgets]
        |> Enum.zip()
        |> Enum.map(fn {amount, budget} ->
          if budget.name == leftover_budget.name do
            {Money.add(leftover_amount, amount), budget}
          else
            {amount, budget}
          end
        end)
        |> Enum.reject(fn {amount, _} -> amount == Money.new(0) end)
        |> Enum.map(&create_transaction(&1, money_attrs, receipt_source_transaction))
      end)

      to = ~p"/transactions?#{socket.assigns.filter_map}"
      {:noreply, push_navigate(socket, to: to)}
    else
      {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp create_transaction({amount, budget}, money_attrs, receipt_source_transaction) do
    money_attrs =
      money_attrs
      |> Map.put("budget_id", budget.id)
      |> Map.put("amount", amount)
      |> Map.put("type", "Credit")

    Transaction.insert_transaction(%Transaction{}, receipt_source_transaction, money_attrs)
  end

  defp get_budget_amounts_by_percents(budgets, paycheck_amount) do
    budgets
    |> Enum.map(fn budget ->
      SimpleBudgeting.Utils.MoneyFunctions.multiply_with_percent(paycheck_amount, budget.percentage / 100)
    end)
  end

  defp get_budget_table_data(budgets, changeset) do
    paycheck_amount =
      changeset.changes
      |> attrs_has_paycheck_amount?()
      |> SimpleBudgeting.Utils.MoneyFunctions.parse_money_in_attrs!(:paycheck_amount)
      |> Map.get(:paycheck_amount)

    budgets
    |> get_budget_amounts_by_percents(paycheck_amount)
    |> Enum.zip(budgets)
  end

  defp attrs_has_paycheck_amount?(attrs) when is_map_key(attrs, :paycheck_amount) do
    attrs
  end

  defp attrs_has_paycheck_amount?(_attrs) do
    %{paycheck_amount: Money.new(0)}
  end

  defp get_location_name(money_attrs) do
    location_name =
      money_attrs
      |> Map.get("location_name", "")

    money_attrs =
      SimpleBudgeting.Schema.Location
      |> SimpleBudgeting.Repo.get_by(name: location_name)
      |> case do
        nil -> money_attrs
        location -> Map.put(money_attrs, "location_id", location.id)
      end

    location_name =
      case location_name do
        nil -> nil
        "" -> nil
        value -> value
      end

    {location_name, money_attrs}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <SimpleBudgetingWeb.Application.Wrapper.wrapper title="Transactions" context="Transactions">
      <.form :let={f} for={@changeset} class="simple_budgeting form" phx-change="change" phx-submit="submit">
        <.card class="max-w-3xl">
          <:header>
            <h3 class="text-lg leading-6 font-medium text-gray-900">Add a new paycheck</h3>
          </:header>
          <div class="grid grid-cols-2 gap-6">
            <div class="flex flex-col">
              <.input
                field={f[:location_name]}
                id="location-selection"
                label="Location*"
                type="search_select"
                options={@locations}
                value={@location_name}
              />
              <.link
                navigate={~p"/locations"}
                class="link"
                target="_blank"
              >
                Create new location
              </.link>
            </div>
            <.input
              field={f[:receipt_source_id]}
              label="Receipt Source*"
              type="select"
              options={@receipt_sources}
            />
          </div>

          <.input field={f[:description]} label="Description" type="text" class="max-w-lg" />
          <.input
            field={f[:paycheck_amount]}
            label="Paycheck Amount*"
            type="money"
            class="max-w-lg"
            id="money_amount"
          />

          <div class="grid grid-cols-2 gap-6">
            <.input
              field={f[:leftover_budget_id]}
              label="Leftover budget*"
              type="select"
              options={@budget_selection}
            />
            <div class="field flex flex-col pt-3">
              <label>Leftover amount</label>
              <label class="!text-black !text-lg font-bold"><%= @leftover %></label>
            </div>
          </div>

          <.input
            field={f[:date_taken]}
            label="Date transaction occured*"
            type="date"
            max={Date.utc_today()}
          />
          <.input
            field={f[:applied]}
            label="Amount applied to account?*"
            type="checkbox"
            class="focus:ring-emerald-500 h-6 w-6 text-emerald-700 border-gray-700 rounded"
          />
          <:footer>
            <div class="flex flex-row justify-end space-x-3">
              <.link
                navigate={~p"/transactions?#{@filter_map}"}
                class="simple_budgeting white button"
              >
                Cancel
              </.link>
              <button
                type="submit"
                disabled={!@changeset.valid?}
                class="simple_budgeting primary button disabled:!cursor-not-allowed disabled:opacity-50"
              >
                Create
              </button>
            </div>
          </:footer>
        </.card>
      </.form>
      <div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg my-12">
        <table class="simple_budgeting table">
          <thead>
            <tr>
              <th>Budget Name</th>
              <th>Percentage</th>
              <th>Paycheck amount to be added (minus leftover)</th>
            </tr>
          </thead>
          <tbody>
            <%= for  {amount, budget} <- get_budget_table_data(@budgets, @changeset) do %>
              <tr>
                <td>
                  <%= budget.name %>
                </td>
                <td>
                  <%= budget.percentage %>%
                </td>
                <td>
                  <%= amount %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </SimpleBudgetingWeb.Application.Wrapper.wrapper>
    """
  end
end
