defmodule SimpleBudgetingWeb.Transactions.New.Transaction do
  @moduledoc false
  use SimpleBudgetingWeb, :live_view

  import Ecto.Query, warn: false
  import Ecto.Changeset

  alias SimpleBudgeting.Schema.Transaction
  alias SimpleBudgetingWeb.Transactions.Filter

  @impl true
  def mount(_params, _uri, socket) do
    receipt_sources =
      from(
        receipt_sources in SimpleBudgeting.Schema.ReceiptSource,
        order_by: receipt_sources.name,
        select: {receipt_sources.name, receipt_sources.id},
        where: receipt_sources.name != "System"
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
        # select: {locations.name, locations.id}
        select: locations.name
      )
      |> SimpleBudgeting.Repo.all()

    transaction = %Transaction{
      description: "",
      type: "Debit",
      amount: Money.new(0),
      applied: false,
      date_taken: Date.utc_today()
    }

    changeset = Transaction.changeset(transaction)

    socket =
      socket
      |> assign(transaction: transaction)
      |> assign(changeset: changeset)
      |> assign(receipt_sources: receipt_sources)
      |> assign(budgets: budgets)
      |> assign(locations: locations)
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
  def handle_event("change", %{"transaction" => attrs}, socket) do
    money_attrs = SimpleBudgeting.Utils.MoneyFunctions.parse_money_in_attrs!(attrs, "amount")
    %{transaction: transaction} = socket.assigns
    %{"receipt_source_id" => receipt_source_id} = attrs

    {location_name, money_attrs} = get_location_name(money_attrs)

    changeset =
      Transaction.changeset(transaction, money_attrs)
      |> Map.put(:action, :insert)

    changeset =
      if is_nil(receipt_source_id) do
        add_error(changeset, :receipt_source_id, "Receipt Source cannot be blank",
          validation: "not nil"
        )
      else
        changeset
      end

    socket =
      socket
      |> assign(changeset: changeset)
      |> assign(location_name: location_name)

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"transaction" => attrs}, socket) do
    money_attrs = SimpleBudgeting.Utils.MoneyFunctions.parse_money_in_attrs!(attrs, "amount")

    {_location_name, money_attrs} = get_location_name(money_attrs)

    %{transaction: transaction} = socket.assigns
    %{"receipt_source_id" => receipt_source_id} = attrs

    changeset =
      Transaction.changeset(transaction, money_attrs)
      |> Map.put(:action, :insert)

    changeset =
      if is_nil(receipt_source_id) do
        add_error(changeset, :receipt_source_id, "Receipt Source cannot be blank",
          validation: "not nil"
        )
      else
        changeset
      end

    if changeset.valid? do
      {:ok, _} = Transaction.insert_transaction(transaction, money_attrs)
      to = ~p"/transactions?#{socket.assigns.filter_map}"
      {:noreply, push_navigate(socket, to: to)}
    else
      {:noreply, assign(socket, changeset: changeset)}
    end
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
            <h3 class="text-lg leading-6 font-medium text-gray-900">Add a new transaction</h3>
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

          <div class="grid grid-cols-2 gap-6">
            <div class="flex flex-col">
              <.input
                field={f[:location_name]}
                label="Location*"
                type="search_select"
                class="max-w-lg"
                id="location-selection"
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
            <.input field={f[:budget_id]} label="Budget*" type="select" options={@budgets} />
          </div>

          <.debit_credit_radio_fieldset field={f[:type]} />

          <.input field={f[:description]} label="Description" type="text" class="max-w-lg" />
          <.input field={f[:amount]} label="Amount*" type="money" id="money_amount" />
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
                class="simple_budgeting primary button disabled:!cursor-not-allowed disabled:opacity-50">
                Create
              </button>
            </div>
          </:footer>
        </.card>
      </.form>
    </SimpleBudgetingWeb.Application.Wrapper.wrapper>
    """
  end
end
