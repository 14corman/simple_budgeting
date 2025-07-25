defmodule SimpleBudgetingWeb.ReceiptSources.Show do
  @moduledoc false
  use SimpleBudgetingWeb, :live_view

  import Ecto.Query, warn: false

  alias SimpleBudgeting.Schema.ReceiptSource

  @impl true
  def mount(_params, _uri, socket) do
    socket =
      socket
      |> assign(edit: false)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _ui, socket) do
    %{"id" => receipt_source_id} = params

    socket =
      socket
      |> assign(receipt_source_id: receipt_source_id)
      |> set_assigns()

    {:noreply, socket}
  end

  @impl true
  def handle_event("change", %{"receipt_source" => params}, socket) do
    changeset =
      socket.assigns.receipt_source
      |> ReceiptSource.changeset(params)
      |> Map.put(:action, :update)

    socket =
      socket
      |> assign(changeset: changeset)

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"receipt_source" => params}, socket) do
    changeset =
      socket.assigns.receipt_source
      |> ReceiptSource.changeset(params)
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
    receipt_source =
      ReceiptSource
      |> SimpleBudgeting.Repo.get(socket.assigns.receipt_source_id)

    changeset = ReceiptSource.changeset(receipt_source)

    socket
    |> assign(receipt_source: receipt_source)
    |> assign(changeset: changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <SimpleBudgetingWeb.Application.Wrapper.wrapper title="Receipt Sources" context="Receipt Sources">
      <.form :let={f} for={@changeset} class="simple_budgeting form" phx-change="change" phx-submit="submit">
        <.card class="max-w-3xl">
          <:header>
            <h3 class="text-lg leading-6 font-medium text-gray-900">
              Receipt Source: <%= @receipt_source.name %>
            </h3>
          </:header>
          <.input field={f[:name]} label="Name" type="text" class="max-w-lg" disabled={!@edit} />
          <.input
            field={f[:description]}
            label="Description"
            type="text"
            class="max-w-lg"
            disabled={!@edit}
          />
          <:footer>
            <div class="flex flex-row justify-end space-x-3">
              <%= if  @edit do %>
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
                  navigate={~p"/receipt_sources"}
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
