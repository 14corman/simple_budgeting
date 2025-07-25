defmodule SimpleBudgetingWeb.ReceiptSources.Index do
  @moduledoc false
  use SimpleBudgetingWeb, :live_view
  import Ecto.Query, warn: false

  alias SimpleBudgeting.Repo
  alias SimpleBudgetingWeb.ReceiptSources.Filter

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(now: nil)
      |> assign(receipt_sources: receipt_sources())

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filter =
      Filter.changeset(%Filter{}, params)
      |> Ecto.Changeset.apply_changes()

    receipt_source = %SimpleBudgeting.Schema.ReceiptSource{
      name: "",
      description: ""
    }

    receipt_source_changeset = SimpleBudgeting.Schema.ReceiptSource.changeset(receipt_source)

    socket =
      socket
      |> assign(filter: filter)
      |> assign(receipt_source_changeset: receipt_source_changeset)
      |> set_assigns()

    {:noreply, socket}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    filters =
      %{socket.assigns.filter | page: page}
      |> Map.from_struct()

    to = ~p"/receipt_sources?#{filters}"
    {:noreply, push_patch(socket, to: to)}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter}, socket) do
    filter =
      filter
      |> Map.put("page", 1)

    to = ~p"/receipt_sources?#{filter}"
    {:noreply, push_patch(socket, to: to)}
  end

  @impl true
  def handle_event("change", %{"receipt_source" => attrs}, socket) do
    receipt_source_changeset =
      %SimpleBudgeting.Schema.ReceiptSource{}
      |> SimpleBudgeting.Schema.ReceiptSource.changeset(attrs)
      |> Map.put(:action, :insert)

    socket =
      socket
      |> assign(receipt_source_changeset: receipt_source_changeset)

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"receipt_source" => attrs}, socket) do
    receipt_source_changeset =
      %SimpleBudgeting.Schema.ReceiptSource{}
      |> SimpleBudgeting.Schema.ReceiptSource.changeset(attrs)
      |> Map.put(:action, :insert)

    if receipt_source_changeset.valid? do
      _receipt_source = SimpleBudgeting.Repo.insert!(receipt_source_changeset)

      to = ~p"/receipt_sources"
      {:noreply, push_navigate(socket, to: to)}
    else
      {:noreply, assign(socket, receipt_source_changeset: receipt_source_changeset)}
    end
  end

  defp receipt_sources() do
    from(
      receipt_sources in SimpleBudgeting.Schema.ReceiptSource,
      select: receipt_sources.name,
      order_by: [asc: receipt_sources.name],
      distinct: true
    )
    |> Repo.all()
  end

  defp set_assigns(socket) do
    queryable =
      from(
        receipt_sources in SimpleBudgeting.Schema.ReceiptSource,
        as: :receipt_sources,
        order_by: [asc: receipt_sources.name],
        select: receipt_sources
      )
      |> Filter.apply_filter(socket.assigns.filter)

    socket
    |> assign(queryable: queryable)
  end
end
