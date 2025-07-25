defmodule SimpleBudgetingWeb.Transactions.Show do
  @moduledoc false
  use SimpleBudgetingWeb, :live_view

  import Ecto.Query, warn: false

  alias SimpleBudgeting.Schema.ReceiptSource.Transaction, as: ReceiptSourceTransaction
  alias SimpleBudgetingWeb.Transactions.Show.HeaderForm
  alias SimpleBudgetingWeb.Transactions.Show.TransactionForm
  alias SimpleBudgetingWeb.Transactions.Filter

  @impl true
  def mount(_params, _uri, socket) do
    socket =
      socket
      |> assign(edit: false)
      |> assign(accounts: accounts())
      |> assign(locations: locations())
      |> assign(receipt_sources: receipt_sources())
      |> assign(budgets: budgets())
      |> assign(transaction_to_delete: nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _ui, socket) do
    %{"id" => receipt_source_transaction_id} = params

    filter_map =
      Filter.changeset(%Filter{}, params)
      |> Ecto.Changeset.apply_changes()
      |> Map.from_struct()

    socket =
      socket
      |> assign(filter_map: filter_map)
      |> assign(receipt_source_transaction_id: receipt_source_transaction_id)
      |> set_assigns()

    {:noreply, socket}
  end

  @impl true
  def handle_event("transaction_change", %{"transaction_form" => attrs}, socket) do
    %{"transaction_id" => transaction_id} = attrs
    money_attrs = SimpleBudgeting.Utils.MoneyFunctions.parse_money_in_attrs!(attrs, "amount")

    {transaction_id, _} = Integer.parse(transaction_id)

    changeset =
      socket.assigns.transaction_forms_map
      |> Map.get(transaction_id)
      |> TransactionForm.changeset(money_attrs)
      |> Map.put(:action, :insert)

    transaction_changesets =
      socket.assigns.transaction_changesets
      |> Map.put(transaction_id, changeset)

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
  def handle_event("change", %{"header_form" => params}, socket) do
    changeset =
      socket.assigns.header_form
      |> HeaderForm.changeset(params)
      |> Map.put(:action, :update)

    socket =
      socket
      |> assign(changeset: changeset)

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"header_form" => params}, socket) do
    changeset =
      socket.assigns.header_form
      |> HeaderForm.changeset(params)
      |> Map.put(:action, :update)

    if are_changesets_valid?(changeset, socket.assigns.transaction_changesets) do
      SimpleBudgeting.Repo.transaction(fn ->
        socket.assigns.receipt_source_transaction
        |> ReceiptSourceTransaction.changeset(params)
        |> SimpleBudgeting.Repo.update!()

        socket.assigns.transaction_changesets
        |> Enum.each(&update_transaction(&1, params, socket))
      end)

      socket =
        socket
        |> assign(edit: false)
        |> set_assigns()

      {:noreply, socket}
    else
      {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("toggle_edit", _params, socket) do
    {:noreply, set_assigns(assign(socket, edit: !socket.assigns.edit))}
  end

  @impl true
  def handle_event("delete_transaction", %{"index" => index}, socket) do
    {index, _} = Integer.parse(index)

    transaction =
      socket.assigns.transactions_map
      |> Map.get(index)
      |> SimpleBudgeting.Repo.preload(:budget)

    socket =
      socket
      |> assign(transaction_to_delete: transaction)
      |> push_show_modal("delete_transaction_confirmation_modal")

    {:noreply, socket}
  end

  @impl true
  def handle_event("approve_delete_transaction", _params, socket) do
    {:ok, receipt_source_transaction_removed?} = SimpleBudgeting.Schema.Transaction.remove_transaction(socket.assigns.transaction_to_delete)

    socket =
      if receipt_source_transaction_removed? do
        to = ~p"/transactions?#{socket.assigns.filter_map}"

        socket
        |> push_hide_modal("delete_transaction_confirmation_modal")
        |> push_navigate(to: to)
      else
        socket
        |> push_hide_modal("delete_transaction_confirmation_modal")
        |> set_assigns()
      end

    {:noreply, socket}
  end

  defp set_assigns(socket) do
    receipt_source_transaction =
      ReceiptSourceTransaction
      |> SimpleBudgeting.Repo.get(socket.assigns.receipt_source_transaction_id)
      |> SimpleBudgeting.Repo.preload(:transactions, force: true)

    header_form = %HeaderForm{
      location_id: List.first(receipt_source_transaction.transactions).location_id,
      receipt_source_id: receipt_source_transaction.receipt_source_id,
      identifier: receipt_source_transaction.identifier,
      type: List.first(receipt_source_transaction.transactions).type
    }

    transactions_map =
      receipt_source_transaction.transactions
      |> Enum.sort_by(& &1.inserted_at)
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {transaction, index}, acc ->
        Map.put(acc, index + 1, transaction)
      end)

    transaction_forms_map =
      transactions_map
      |> Enum.map(fn {index, transaction} ->
        {
          index,
          %TransactionForm{
            description: transaction.description,
            amount: transaction.amount,
            budget_id: transaction.budget_id,
            applied: transaction.applied,
            date_taken: transaction.date_taken
          }
        }
      end)
      |> Enum.into(%{})

    transaction_changesets =
      transaction_forms_map
      |> Enum.map(fn {index, form} -> {index, TransactionForm.changeset(form)} end)
      |> Enum.into(%{})

    total_amount =
      receipt_source_transaction.transactions
      |> Enum.reduce(Money.new(0), fn transaction, acc -> Money.add(transaction.amount, acc) end)

    changeset = HeaderForm.changeset(header_form)

    socket
    |> assign(header_form: header_form)
    |> assign(receipt_source_transaction: receipt_source_transaction)
    |> assign(changeset: changeset)
    |> assign(total_amount: total_amount)
    |> assign(transaction_changesets: transaction_changesets)
    |> assign(transactions_map: transactions_map)
    |> assign(transaction_forms_map: transaction_forms_map)
  end

  defp update_transaction({index, changeset}, header_form_params, socket) do
    transaction_form_params =
      changeset
      |> Ecto.Changeset.apply_changes()
      |> Map.from_struct()
      |> Enum.map(fn {key, value} -> {"#{key}", value} end)
      |> Enum.into(%{})
      |> Map.merge(header_form_params)

    transaction =
      socket.assigns.transactions_map
      |> Map.get(index)
      |> SimpleBudgeting.Repo.preload(:budget)

    SimpleBudgeting.Repo.transaction(fn ->
      if transaction.applied do
        {:ok, _} = SimpleBudgeting.Schema.Transaction.undo_transaction(transaction)
      end

      transaction =
        transaction
        |> SimpleBudgeting.Schema.Transaction.changeset(transaction_form_params)
        |> SimpleBudgeting.Repo.update!()
        |> SimpleBudgeting.Repo.preload(:budget, force: true)

      if transaction.applied do
        {:ok, _} = SimpleBudgeting.Schema.Transaction.apply_transaction(transaction)
      end
    end)
  end

  defp accounts() do
    from(
      accounts in SimpleBudgeting.Schema.Account,
      order_by: [asc: accounts.name],
      select: {accounts.name, accounts.id},
      distinct: true
    )
    |> SimpleBudgeting.Repo.all()
  end

  defp locations() do
    from(
      locations in SimpleBudgeting.Schema.Location,
      select: {locations.name, locations.id},
      order_by: [asc: locations.name],
      distinct: true
    )
    |> SimpleBudgeting.Repo.all()
  end

  defp budgets() do
    from(
      budgets in SimpleBudgeting.Schema.Budget,
      select: {budgets.name, budgets.id},
      order_by: [asc: budgets.name],
      distinct: true
    )
    |> SimpleBudgeting.Repo.all()
  end

  defp receipt_sources() do
    from(
      receipt_sources in SimpleBudgeting.Schema.ReceiptSource,
      select: {receipt_sources.name, receipt_sources.id},
      order_by: [asc: receipt_sources.name],
      distinct: true
    )
    |> SimpleBudgeting.Repo.all()
  end

  defp are_changesets_valid?(changeset, transaction_changesets) do
    is_valid = changeset.valid?

    Enum.reduce(transaction_changesets, is_valid, fn {_index, changeset}, is_valid ->
      changeset.valid? && is_valid
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <SimpleBudgetingWeb.Application.Wrapper.wrapper title="Transactions" context="Transactions">
      <.form :let={f} for={@changeset} class="simple_budgeting form" phx-change="change" phx-submit="submit">
        <.card class="max-w-3xl">
          <:header>
            <h3 class="text-lg leading-6 font-medium text-gray-900">Transaction:</h3>
          </:header>
          <div class="grid grid-cols-2 gap-6">
            <.input
              field={f[:receipt_source_id]}
              label="Receipt Source*"
              type="select"
              options={@receipt_sources}
              disabled={!@edit}
            />
            <.input
              field={f[:identifier]}
              label="Receipt Identifier"
              class="max-w-lg"
              type="text"
              disabled={!@edit}
            />
          </div>

          <.input
            field={f[:location_id]}
            label="Location*"
            type="select"
            options={@locations}
            disabled={!@edit}
          />

          <.debit_credit_radio_fieldset field={f[:type]} disabled={!@edit} />
          <div class="field flex flex-col pt-3">
            <label>Total amount</label>
            <label class="!text-black !text-lg font-bold"><%= @total_amount %></label>
          </div>
          <:footer>
            <div class="flex flex-row justify-end space-x-3">
              <%= if @edit do %>
                <a phx-click="toggle_edit" class="simple_budgeting white button cursor-pointer">
                  Cancel
                </a>
                <button
                  type="submit"
                  class="simple_budgeting primary button disabled:opacity-50 disabled:!cursor-not-allowed"
                  disabled={!are_changesets_valid?(@changeset, @transaction_changesets)}
                >
                  Submit
                </button>
              <% else %>
                <a phx-click="toggle_edit" class="simple_budgeting white button cursor-pointer">
                  Edit
                </a>
                <.link
                  navigate={~p"/transactions?#{@filter_map}"}
                  class="simple_budgeting primary button"
                >
                  Return
                </.link>
              <% end %>
            </div>
          </:footer>
        </.card>
      </.form>
      <section class="w-full my-12">
        <div class="bg-white shadow overflow-hidden sm:rounded-md">
          <ul role="list" class="divide-y divide-gray-200">
            <%= for {index, transaction_changeset} <- @transaction_changesets |> Enum.sort_by(fn {index, _} -> index end) do %>
              <li class="group hover:bg-gray-50 border-l-[6px] !border-emerald-500 hover:!border-emerald-700">
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
                  <.input
                    field={f[:budget_id]}
                    label="Budget*"
                    type="select"
                    options={@budgets}
                    disabled={!@edit}
                  />
                  <.input
                    field={f[:amount]}
                    label="Amount*"
                    type="money"
                    class="max-w-lg"
                    disabled={!@edit}
                    id={"money_amount_#{index}"}
                  />
                  <.input
                    field={f[:description]}
                    label="Description"
                    type="text"
                    class="max-w-lg"
                    disabled={!@edit}
                  />
                  <.input
                    field={f[:date_taken]}
                    label="Date transaction occured*"
                    type="date"
                    class="max-w-lg"
                    max={Date.utc_today()}
                    disabled={!@edit}
                  />
                  <.input
                    field={f[:applied]}
                    label="Amount applied to account?*"
                    type="checkbox"
                    class="focus:ring-emerald-500 h-6 w-6 text-emerald-700 border-gray-700 rounded"
                    disabled={!@edit}
                  />
                  <a phx-click="delete_transaction" phx-value-index={index} class="simple_budgeting button danger cursor-pointer">
                    Delete
                  </a>
                </.form>
              </li>
            <% end %>
          </ul>
        </div>
      </section>

      <.confirm_danger_modal
        id="delete_transaction_confirmation"
        title="Delete transaction?"
        on_confirm="approve_delete_transaction"
      >
        <p>Are you sure you want to delete the following transaction?</p>
        <p class="font-bold mb-2 text-red-500">This action cannot be undone!</p>
        <%= if @transaction_to_delete do %>
          <p>
            <label class="font-bold">Budget</label>: <%= @transaction_to_delete.budget.name %>
          </p>
          <p>
            <label class="font-bold">Amount</label>: <%= @transaction_to_delete.amount %>
          </p>
          <p>
            <label class="font-bold">Description</label>: <%= @transaction_to_delete.description %>
          </p>
        <% end %>
      </.confirm_danger_modal>
    </SimpleBudgetingWeb.Application.Wrapper.wrapper>
    """
  end
end
