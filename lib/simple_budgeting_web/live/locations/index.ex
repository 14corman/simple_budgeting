defmodule SimpleBudgetingWeb.Locations.Index do
  @moduledoc false
  use SimpleBudgetingWeb, :live_view
  import Ecto.Query, warn: false

  alias SimpleBudgeting.Repo
  alias SimpleBudgetingWeb.Locations.Filter

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(now: nil)
      |> assign(locations: locations())
      |> assign(months: months())
      |> assign(years: years())

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filter =
      Filter.changeset(%Filter{}, params)
      |> Ecto.Changeset.apply_changes()

    location = %SimpleBudgeting.Schema.Location{
      name: "",
      description: ""
    }

    location_changeset = SimpleBudgeting.Schema.Location.changeset(location)

    socket =
      socket
      |> assign(filter: filter)
      |> assign(location_changeset: location_changeset)
      |> set_assigns()

    {:noreply, socket}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    filters =
      %{socket.assigns.filter | page: page}
      |> Map.from_struct()

    to = ~p"/locations?#{filters}"
    {:noreply, push_patch(socket, to: to)}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter}, socket) do
    filter =
      filter
      |> Map.put("page", 1)

    to = ~p"/locations?#{filter}"
    {:noreply, push_patch(socket, to: to)}
  end

  @impl true
  def handle_event("change", %{"location" => attrs}, socket) do
    location_changeset =
      %SimpleBudgeting.Schema.Location{}
      |> SimpleBudgeting.Schema.Location.changeset(attrs)
      |> Map.put(:action, :insert)

    socket =
      socket
      |> assign(location_changeset: location_changeset)

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"location" => attrs}, socket) do
    location_changeset =
      %SimpleBudgeting.Schema.Location{}
      |> SimpleBudgeting.Schema.Location.changeset(attrs)
      |> Map.put(:action, :insert)

    if location_changeset.valid? do
      _location = SimpleBudgeting.Repo.insert!(location_changeset)

      to = ~p"/locations"
      {:noreply, push_navigate(socket, to: to)}
    else
      {:noreply, assign(socket, location_changeset: location_changeset)}
    end
  end

  defp locations() do
    from(
      locations in SimpleBudgeting.Schema.Location,
      select: locations.name,
      order_by: [asc: locations.name],
      distinct: true
    )
    |> Repo.all()
  end

  defp years() do
    from(
      transactions in SimpleBudgeting.Schema.Transaction,
      select: fragment("EXTRACT(YEAR FROM ?)::int", transactions.date_taken),
      distinct: true
    )
    |> Repo.all()
    |> Enum.sort()
  end

  defp months() do
    from(
      transactions in SimpleBudgeting.Schema.Transaction,
      select: fragment("EXTRACT(MONTH FROM ?)::int", transactions.date_taken),
      distinct: true
    )
    |> Repo.all()
    |> Enum.sort()
  end

  defp set_assigns(socket) do
    queryable =
      from(
        locations in SimpleBudgeting.Schema.Location,
        as: :locations,
        order_by: [asc: locations.name],
        select: locations
      )
      |> Filter.apply_filter(socket.assigns.filter)

    socket
    |> assign(queryable: queryable)
  end

  defp month_string_to_int(month) do
    case month do
      "January" -> 1
      "February" -> 2
      "March" -> 3
      "April" -> 4
      "May" -> 5
      "June" -> 6
      "July" -> 7
      "August" -> 8
      "September" -> 9
      "October" -> 10
      "November" -> 11
      "December" -> 12
      _ -> -1
    end
  end

  defp calc_total_debits(transactions, filter) do
    month_int = month_string_to_int(filter.month)

    transactions
    |> Enum.filter(
      &(&1.type == "Debit" && (month_int == -1 || &1.date_taken.month == month_int) &&
          (is_nil(filter.year) || filter.year == &1.date_taken.year))
    )
    |> Enum.reduce(Money.new(0), fn transaction, acc -> Money.add(transaction.amount, acc) end)
  end

  defp calc_total_credits(transactions, filter) do
    month_int = month_string_to_int(filter.month)

    transactions
    |> Enum.filter(
      &(&1.type == "Credit" && (month_int == -1 || &1.date_taken.month == month_int) &&
          (is_nil(filter.year) || filter.year == &1.date_taken.year))
    )
    |> Enum.reduce(Money.new(0), fn transaction, acc -> Money.add(transaction.amount, acc) end)
  end
end
