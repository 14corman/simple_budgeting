defmodule SimpleBudgetingWeb.Transactions.New.CompoundTransaction do
  @moduledoc false
  use SimpleBudgetingWeb, :live_view

  import Ecto.Query, warn: false
  import Ecto.Changeset

  alias SimpleBudgetingWeb.Transactions.Filter
  alias SimpleBudgeting.Schema.Transaction
  alias SimpleBudgetingWeb.Transactions.New.CompoundTransaction.HeaderForm
  alias SimpleBudgetingWeb.Transactions.New.CompoundTransaction.TransactionForm

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
        where: budgets.open,
        select: {budgets.name, budgets.id}
      )
      |> SimpleBudgeting.Repo.all()

    locations =
      from(
        locations in SimpleBudgeting.Schema.Location,
        order_by: locations.name,
        select: locations.name
      )
      |> SimpleBudgeting.Repo.all()

    changeset = HeaderForm.changeset(%HeaderForm{date_taken: Date.utc_today()}, %{})
    transaction_changeset = TransactionForm.changeset(%TransactionForm{}, %{})

    transaction_changeset
    |> Ecto.Changeset.apply_changes()

    socket =
      socket
      |> assign(changeset: changeset)
      |> assign(receipt_sources: receipt_sources)
      |> assign(budgets: budgets)
      |> assign(locations: locations)
      |> assign(total_amount: Money.new(0))
      |> assign(transaction_changesets: %{"1" => transaction_changeset})
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
  def handle_event("transaction_change", %{"transaction_form" => attrs}, socket) do
    %{"transaction_id" => transaction_id} = attrs
    money_attrs = SimpleBudgeting.Utils.MoneyFunctions.parse_money_in_attrs!(attrs, "amount")

    changeset =
      TransactionForm.changeset(%TransactionForm{}, money_attrs)
      |> Map.put(:action, :insert)

    transaction_changesets =
      socket.assigns.transaction_changesets
      |> Map.put("#{transaction_id}", changeset)

    new_total_amount =
      transaction_changesets
      |> Enum.map(fn {_key, changeset} -> Ecto.Changeset.apply_changes(changeset) end)
      |> Enum.map(& &1.amount)
      |> Enum.reduce(Money.new(0), fn amount, acc -> Money.add(amount, acc) end)

    socket =
      socket
      |> assign(transaction_changesets: transaction_changesets)
      |> assign(total_amount: new_total_amount)

    {:noreply, socket}
  end

  @impl true
  def handle_event("header_change", %{"header_form" => attrs}, socket) do
    header = Ecto.Changeset.apply_changes(socket.assigns.changeset)

    {location_name, attrs} = get_location_name(attrs)

    changeset =
      HeaderForm.changeset(header, attrs)
      |> Map.put(:action, :insert)

    number_transactions = get_change(changeset, :number_transactions, nil)

    new_total_amount =
      if number_transactions do
        Money.new(0)
      else
        socket.assigns.total_amount
      end

    transaction_changesets =
      if number_transactions do
        Enum.reduce(1..number_transactions, %{}, fn num, acc ->
          Map.put(acc, "#{num}", TransactionForm.changeset(%TransactionForm{}, %{}))
        end)
      else
        socket.assigns.transaction_changesets
      end

    socket =
      socket
      |> assign(changeset: changeset)
      |> assign(transaction_changesets: transaction_changesets)
      |> assign(total_amount: new_total_amount)
      |> assign(location_name: location_name)

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"header_form" => attrs}, socket) do
    {_location_name, attrs} = get_location_name(attrs)
    header = Ecto.Changeset.apply_changes(socket.assigns.changeset)

    changeset =
      HeaderForm.changeset(header, attrs)
      |> Map.put(:action, :insert)

    if all_changesets_valid?(changeset, socket.assigns.transaction_changesets) do
      SimpleBudgeting.Repo.transaction(fn ->
        receipt_source_transaction =
          %SimpleBudgeting.Schema.ReceiptSource.Transaction{}
          |> SimpleBudgeting.Schema.ReceiptSource.Transaction.changeset(attrs)
          |> SimpleBudgeting.Repo.insert!()

        socket.assigns.transaction_changesets
        |> Enum.each(fn {_index, transaction_changesets} ->
          insert_transaction(attrs, receipt_source_transaction, transaction_changesets, header)
        end)
      end)

      to = ~p"/transactions?#{socket.assigns.filter_map}"
      {:noreply, push_navigate(socket, to: to)}
    else
      {:noreply, socket}
    end
  end

  defp all_changesets_valid?(changeset, transaction_changesets) do
    transactions_ok =
      transaction_changesets
      |> Enum.reduce(true, fn {_, changeset}, acc -> changeset.valid? && acc end)

    transactions_ok && changeset.valid?
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

  defp insert_transaction(attrs, receipt_source_transaction, transaction_changeset, header) do
    money_transaction_attrs =
      transaction_changeset
      |> Ecto.Changeset.apply_changes()
      |> Map.from_struct()
      |> Enum.map(fn {key, value} -> {"#{key}", value} end)
      |> Enum.into(%{})
      |> Map.merge(%{
        "location_id" => attrs["location_id"],
        "type" => attrs["type"],
        "applied" => header.applied,
        "date_taken" => header.date_taken
      })
      |> SimpleBudgeting.Utils.MoneyFunctions.parse_money_in_attrs!("amount")

    {:ok, _} =
      Transaction.insert_transaction(
        %Transaction{},
        receipt_source_transaction,
        money_transaction_attrs
      )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <SimpleBudgetingWeb.Application.Wrapper.wrapper title="Transactions" context="Transactions">
      <.form :let={f} for={@changeset} class="simple_budgeting form" phx-change="header_change" phx-submit="submit">
        <.card class="max-w-3xl">
          <:header>
            <h3 class="text-lg leading-6 font-medium text-gray-900">Add new compound transactions</h3>
          </:header>
          <div class="grid grid-cols-2 gap-6">
            <.input
              field={f[:receipt_source_id]}
              label="Receipt Source*"
              type="select"
              options={@receipt_sources}
            />
            <.input field={f[:identifier]} label="Receipt Identifier" type="text" class="max-w-lg" />
          </div>

          <div class="flex flex-col">
            <.input
              field={f[:location_name]}
              id="location-selection"
              options={@locations}
              value={@location_name}
              label="Location*"
              type="search_select"
            />
            <.link
              navigate={~p"/locations"}
              class="link"
              target="_blank"
            >
              Create new location
            </.link>
          </div>

          <.debit_credit_radio_fieldset field={f[:type]} />

          <.input
            field={f[:date_taken]}
            label="Date transaction occured*"
            type="date"
            max={Date.utc_today()}
          />

          <.input
            field={f[:number_transactions]}
            label="Number of transactions*"
            type="number"
            class="max-w-lg"
            min="1"
          />

          <div class="mt-2 flex flex-row justify-end">
            <.input
              field={f[:applied]}
              label="Applied to account?*"
              type="checkbox"
              class="focus:ring-emerald-500 h-6 w-6 text-emerald-700 border-gray-700 rounded r-0"
            />
          </div>

          <div class="field flex flex-col pt-3">
            <label>Total amount</label>
            <label class="!text-black !text-lg font-bold"><%= @total_amount %></label>
          </div>
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
                disabled={!all_changesets_valid?(@changeset, @transaction_changesets)}
                class="simple_budgeting primary button disabled:!cursor-not-allowed disabled:opacity-50"
              >
                Create
              </button>
            </div>
          </:footer>
        </.card>
      </.form>
      <section class="w-full my-12">
        <div class="bg-white shadow overflow-hidden sm:rounded-md">
          <ul role="list" class="divide-y divide-gray-200">
            <%= for  {index, transaction_changeset} <- @transaction_changesets do %>
              <li class="group hover:bg-gray-50 border-l-[6px] !border-blue-500 hover:!border-blue-700">
                <h1 class="font-bold pl-2 pt-2">Transaction <%= index %></h1>
                <.form
                  :let={f}
                  for={transaction_changeset}
                  id={"transaction_form_#{index}"}
                  class="simple_budgeting form flex flex-col md:flex-row md:items-center justify-around py-1 md:pb-5"
                  phx-change="transaction_change"
                  phx-submit="transaction_change"
                >
                  <.input field={f[:transaction_id]} type="hidden" value={index} />
                  <.input field={f[:budget_id]} label="Budget*" type="select" options={@budgets} />
                  <.input
                    field={f[:amount]}
                    label="Amount*"
                    type="money"
                    class="max-w-lg"
                    id={"money_amount_#{index}"}
                  />
                  <.input field={f[:description]} label="Description" type="text" class="max-w-lg" />
                </.form>
              </li>
            <% end %>
          </ul>
        </div>
      </section>
    </SimpleBudgetingWeb.Application.Wrapper.wrapper>
    """
  end
end
