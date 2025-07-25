defmodule SimpleBudgetingWeb.Budgets.Show do
  @moduledoc false
  use SimpleBudgetingWeb, :live_view

  import Ecto.Query, warn: false

  alias SimpleBudgeting.Schema.Budget

  @impl true
  def mount(_params, _uri, socket) do
    socket =
      socket
      |> assign(edit: false)
      |> assign(accounts: accounts())

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _ui, socket) do
    %{"id" => budget_id} = params

    socket =
      socket
      |> assign(budget_id: budget_id)
      |> set_assigns()

    {:noreply, socket}
  end

  @impl true
  def handle_event("change", %{"budget" => params}, socket) do
    money_attrs = SimpleBudgeting.Utils.MoneyFunctions.parse_money_in_attrs!(params, "amount")

    changeset =
      socket.assigns.budget
      |> Budget.changeset(money_attrs)
      |> Map.put(:action, :update)

    socket =
      socket
      |> assign(changeset: changeset)

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"budget" => params}, socket) do
    money_attrs = SimpleBudgeting.Utils.MoneyFunctions.parse_money_in_attrs!(params, "amount")

    changeset =
      socket.assigns.budget
      |> Budget.changeset(money_attrs)
      |> Map.put(:action, :update)

    if changeset.valid? do
      SimpleBudgeting.Repo.update!(changeset)

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

  defp set_assigns(socket) do
    budget =
      Budget
      |> SimpleBudgeting.Repo.get(socket.assigns.budget_id)

    money_float = SimpleBudgeting.Utils.MoneyFunctions.money_to_float(budget.amount)

    changeset = Budget.changeset(budget)

    socket
    |> assign(budget: budget)
    |> assign(changeset: changeset)
    |> assign(amount_string: money_float)
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

  @impl true
  def render(assigns) do
    ~H"""
    <SimpleBudgetingWeb.Application.Wrapper.wrapper title="Budgets" context="Budgets">
      <.form :let={f} for={@changeset} class="simple_budgeting form" phx-change="change" phx-submit="submit">
        <.card class="max-w-3xl">
          <:header>
            <h3 class="text-lg leading-6 font-medium text-gray-900">Budget: <%= @budget.name %></h3>
          </:header>

          <.input field={f[:name]} label="Name" type="text" class="max-w-lg" disabled={!@edit} />
          <.input
            field={f[:description]}
            label="Description"
            type="text"
            class="max-w-lg"
            disabled={!@edit}
          />
          <.input
            field={f[:percentage]}
            label="Alloted paycheck percent"
            type="number"
            class="max-w-lg"
            min="0.00"
            step="0.001"
            disabled={!@edit}
          />
          <.input
            field={f[:account_id]}
            label="Account to link"
            type="select"
            class="max-w-lg"
            options={@accounts}
            disabled={!@edit}
          />
          <.input
            field={f[:amount]}
            label="Current amount"
            type="money"
            class="max-w-lg"
            id="money_amount"
            disabled={!@edit}
          />
          <:footer>
            <div class="flex flex-row justify-end space-x-3">
              <%= if @edit do %>
                <a phx-click="toggle_edit" class="simple_budgeting white button cursor-pointer">
                  Cancel
                </a>
                <button
                  type="submit"
                  class="simple_budgeting primary button disabled:opacity-50 disabled:!cursor-not-allowed"
                  disabled={!@changeset.valid?}
                >
                  Submit
                </button>
              <% else %>
                <a phx-click="toggle_edit" class="simple_budgeting white button cursor-pointer">
                  Edit
                </a>
                <.link
                  navigate={~p"/budgets"}
                  class="simple_budgeting primary button"
                >
                  Return
                </.link>
              <% end %>
            </div>
          </:footer>
        </.card>
      </.form>
    </SimpleBudgetingWeb.Application.Wrapper.wrapper>
    """
  end
end
