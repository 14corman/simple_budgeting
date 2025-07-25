defmodule SimpleBudgetingWeb.Transactions.Index do
  @moduledoc false
  use SimpleBudgetingWeb, :live_view
  import Ecto.Query, warn: false

  alias SimpleBudgeting.Repo
  alias SimpleBudgetingWeb.Transactions.Filter

  @impl true
  def mount(_params, _session, socket) do
    year = to_string(Date.utc_today().year)
    restores_options = SimpleBudgeting.Utils.DBFunctions.find_dump_files!()

    filtered_restores =
      restores_options
      |> Enum.filter(& &1.is_balanced == true && &1.year_dir == year)

    first_selected_restore = List.first(filtered_restores) || %{}

    socket =
      socket
      |> assign(now: nil)
      |> assign(budgets: budgets())
      |> assign(locations: locations())
      |> assign(receipt_codes: receipt_codes())
      |> assign(months: months())
      |> assign(years: years())
      |> assign(order_direction: :desc)
      |> assign(order_variable: "date_taken")
      |> assign(save_data_form_date: Date.utc_today())
      |> assign(save_data_form_is_balanced: false)
      |> assign(restore_data_form_year: year)
      |> assign(restore_data_form_is_balanced: true)
      |> assign(restores_options: restores_options)
      |> assign(restore_data_form_filtered_restores: filtered_restores)
      |> assign(restore_data_form_selected_restore: first_selected_restore)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    today = Date.utc_today()

    month =
      case today.month do
        1 -> "January"
        2 -> "February"
        3 -> "March"
        4 -> "April"
        5 -> "May"
        6 -> "June"
        7 -> "July"
        8 -> "August"
        9 -> "September"
        10 -> "October"
        11 -> "November"
        12 -> "December"
      end

    params =
      params
      |> Map.put_new("month", month)
      |> Map.put_new("year", to_string(today.year))

    filter =
      Filter.changeset(%Filter{}, params)
      |> Ecto.Changeset.apply_changes()

    socket =
      socket
      |> assign(filter: filter)
      |> assign(filter_map: Map.from_struct(filter))
      |> set_assigns()

    {:noreply, socket}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    filters =
      %{socket.assigns.filter | page: page}
      |> Map.from_struct()

    to = ~p"/transactions?#{filters}"
    {:noreply, push_patch(socket, to: to)}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter}, socket) do
    filter =
      filter
      |> Map.put("page", 1)
      |> Map.put_new("status", nil)

    to = ~p"/transactions?#{filter}"
    {:noreply, push_patch(socket, to: to)}
  end

  @impl true
  def handle_event("save_data_submit", %{"save_data" => %{"date" => date, "is_balanced" => is_balanced}}, socket) do
    socket =
      if date == "" do
        put_flash(socket, :error, "Date entered is not valid")
      else
        # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!ONLY RUN THIS IN DEV, NEVER IN PROD!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        if Mix.env() == :dev do
          date = Date.from_iso8601!(date)
          date_string = SimpleBudgeting.Utils.DBFunctions.date_to_string(date)
          is_balanced = is_balanced == "true"

          file_suffix =
            if is_balanced do
              "#{date_string}_BALANCED"
            else
              date_string
            end

          case SimpleBudgeting.Utils.DBFunctions.dump_db(file_suffix, date.year) do
            :ok -> put_flash(socket, :info, "Data successfully saved")
            :dump_error -> put_flash(socket, :error, "Error occured while saving")
            :make_file_error -> put_flash(socket, :error, "Unable to create directory to save file")
          end
          |> push_hide_modal("save_data_modal")
        end
        # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("restore_data_change", %{"_target" => ["restore_data", var], "restore_data" => %{"year" => year, "is_balanced" => is_balanced} = attrs}, socket) do
    %{restores_options: restores_options} = socket.assigns
    is_balanced = is_balanced == "true"

    filtered_restores =
      restores_options
      |> Enum.filter(& &1.is_balanced == is_balanced && &1.year_dir == year)

    first_selected_restore =
      if var == "date" do
        date =
          attrs
          |> Map.get("date", "")
          |> case do
            "" -> Date.utc_today()
            nil -> Date.utc_today()
            date -> SimpleBudgeting.Utils.DBFunctions.string_to_date(date)
          end

        filtered_restores
        |> Enum.filter(& &1.date == date)
        |> then(& List.first(&1) || %{})
      else
        List.first(filtered_restores) || %{}
      end

    socket =
      socket
      |> assign(restore_data_form_year: year)
      |> assign(restore_data_form_is_balanced: is_balanced)
      |> assign(restore_data_form_filtered_restores: filtered_restores)
      |> assign(restore_data_form_selected_restore: first_selected_restore)

    {:noreply, socket}
  end

  @impl true
  def handle_event("restore_data_submit", %{"restore_data" => %{"file_name" => file_name, "year" => year}}, socket) do
    socket =
      # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!ONLY RUN THIS IN DEV, NEVER IN PROD!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      if Mix.env() == :dev do
        case SimpleBudgeting.Utils.DBFunctions.restore_db(file_name, year) do
          :ok -> put_flash(socket, :info, "Data successfully saved")
          :restore_error -> put_flash(socket, :error, "Error occured while restoring")
          :file_exists_error -> put_flash(socket, :error, "Unable to find file")
        end
        |> push_hide_modal("restore_data_modal")
      end
      # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    {:noreply, socket}
  end

  @impl true
  def handle_event("change", %{"transaction_applied" => attrs}, socket) do
    %{"id" => id, "applied" => applied} = attrs

    transaction_changeset =
      SimpleBudgeting.Repo.get(SimpleBudgeting.Schema.Transaction, id)
      |> SimpleBudgeting.Schema.Transaction.changeset(%{applied: applied})
      |> Map.put(:action, :update)

    if transaction_changeset.valid? && transaction_changeset.changes != %{} do
      SimpleBudgeting.Repo.transaction(fn ->
        transaction =
          transaction_changeset
          |> SimpleBudgeting.Repo.update!()
          |> SimpleBudgeting.Repo.preload(:budget)

        if applied == "true" do
          # Applying Debit or Credit
          {:ok, _} = SimpleBudgeting.Schema.Transaction.apply_transaction(transaction)
        else
          # Undoing debit or Credit
          {:ok, _} = SimpleBudgeting.Schema.Transaction.undo_transaction(transaction)
        end
      end)

      {:noreply, set_assigns(socket)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("reorder", %{"variable" => value}, socket) do
    new_order =
      cond do
        socket.assigns.order_variable != value -> :asc
        socket.assigns.order_direction == :asc -> :desc
        socket.assigns.order_direction == :asc -> :desc
        true -> :asc
      end

    socket =
      socket
      |> assign(order_direction: new_order)
      |> assign(order_variable: value)
      |> set_assigns()

    {:noreply, socket}
  end

  @impl true
  def handle_event("reblance_budgets", _, socket) do
    # Check if this works first without these 2 lines
    socket.assigns.budgets
    |> Enum.each(&SimpleBudgeting.Schema.Budget.reblance_budget/1)

    socket =
      socket
      |> set_assigns()

    {:noreply, socket}
  end

  defp budgets() do
    from(
      budgets in SimpleBudgeting.Schema.Budget,
      # select: budgets.name,
      order_by: [asc: budgets.name],
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
    |> then(fn list ->
      current_year = Date.utc_today().year
      if Enum.member?(list, current_year) do
        list
      else
        [current_year | list]
      end
    end)
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

  defp receipt_codes() do
    from(
      receipt_codes in SimpleBudgeting.Schema.ReceiptSource,
      select: receipt_codes.name,
      order_by: [asc: receipt_codes.name],
      distinct: true
    )
    |> Repo.all()
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

  defp set_assigns(socket) do
    receipt_code_queryable =
      from(rst in SimpleBudgeting.Schema.ReceiptSource.Transaction,
        as: :rst,
        join: receipt_sources in assoc(rst, :receipt_source),
        select: %{
          id: rst.id,
          receipt_code:
            fragment("? || ' : ' ||  COALESCE(?, 'N/A')", receipt_sources.name, rst.identifier)
        },
        group_by: [rst.id, receipt_sources.name]
      )

    rst_combined_amount_queryable =
      from(rst in SimpleBudgeting.Schema.ReceiptSource.Transaction,
        as: :rst,
        join: transactions in assoc(rst, :transactions),
        select: %{
          id: rst.id,
          combined_amounts: type(
            fragment("jsonb_build_object('amount', ?, 'currency', 'USD')",
              sum(type(
                fragment("(?->?)", transactions.amount, "amount"),
              :integer))
            ), Money.Ecto.Map.Type
          )
        },
        group_by: [rst.id]
      )

    queryable =
      from(
        rst in SimpleBudgeting.Schema.ReceiptSource.Transaction,
        as: :rst,
        join: receipt_sources in assoc(rst, :receipt_source),
        as: :receipt_sources,
        join: receipt_code_subquery in subquery(receipt_code_queryable),
        on: rst.id == receipt_code_subquery.id,
        as: :receipt_code_subquery,
        join: rst_combined_amount_subquery in subquery(rst_combined_amount_queryable),
        on: rst.id == rst_combined_amount_subquery.id,
        as: :rst_combined_amount_subquery,
        join: transactions in assoc(rst, :transactions),
        as: :transactions,
        join: locations in assoc(transactions, :location),
        as: :locations,
        join: budgets in assoc(transactions, :budget),
        as: :budgets,
        select: %{
          date_taken: transactions.date_taken,
          id: rst.id,
          budget_name: budgets.name,
          receipt_code: receipt_code_subquery.receipt_code,
          combined_amounts: rst_combined_amount_subquery.combined_amounts,
          location_name: locations.name,
          description: transactions.description,
          type: transactions.type,
          transaction_amount: transactions.amount,
          applied: transactions.applied,
          transaction_id: transactions.id
        }
      )
      |> Filter.apply_filter(socket.assigns.filter)

    queryable =
      case {socket.assigns.order_direction, socket.assigns.order_variable} do
        {:asc, "date_taken"} ->
          order_by(queryable, [transactions: t], asc: t.date_taken)

        {:desc, "date_taken"} ->
          order_by(queryable, [transactions: t], desc: t.date_taken)

        {:asc, "budget_name"} ->
          order_by(queryable, [budgets: b], asc: b.name)

        {:desc, "budget_name"} ->
          order_by(queryable, [budgets: b], desc: b.name)

        {:asc, "receipt_code"} ->
          order_by(queryable, [receipt_code_subquery: r], asc: r.receipt_code)

        {:desc, "receipt_code"} ->
          order_by(queryable, [receipt_code_subquery: r], desc: r.receipt_code)

        {:asc, "combined_amount"} ->
          order_by(queryable, [rst_combined_amount_subquery: r], asc: r.combined_amounts)

        {:desc, "combined_amount"} ->
          order_by(queryable, [rst_combined_amount_subquery: r], desc: r.combined_amounts)

        {:asc, "location_name"} ->
          order_by(queryable, [locations: l], asc: l.name)

        {:desc, "location_name"} ->
          order_by(queryable, [locations: l], desc: l.name)

        {:asc, "description"} ->
          order_by(queryable, [transactions: t], asc: t.description)

        {:desc, "description"} ->
          order_by(queryable, [transactions: t], desc: t.description)

        {:asc, "debit"} ->
          order_by(queryable, [transactions: t], desc: t.type, asc: t.amount)

        {:desc, "debit"} ->
          order_by(queryable, [transactions: t], desc: t.type, desc: t.amount)

        {:asc, "credit"} ->
          order_by(queryable, [transactions: t], asc: t.type, asc: t.amount)

        {:desc, "credit"} ->
          order_by(queryable, [transactions: t], asc: t.type, desc: t.amount)

        {:asc, "amount"} ->
          order_by(queryable, [transactions: t], asc: t.amount)

        {:desc, "amount"} ->
          order_by(queryable, [transactions: t], desc: t.amount)
      end
      |> order_by([rst: r, transactions: t], asc: r.inserted_at, asc: t.inserted_at, asc: t.id)

    {total_debits, total_credits} =
      queryable
      |> SimpleBudgeting.Repo.all()
      |> Enum.reduce({Money.new(0), Money.new(0)}, fn row, {total_debits, total_credits} ->
        if row.type == "Debit" do
          {Money.add(total_debits, row.transaction_amount), total_credits}
        else
          {total_debits, Money.add(total_credits, row.transaction_amount)}
        end
      end)

    total_adjustments =
      total_debits
      |> Money.neg()
      |> Money.add(total_credits)

    socket
    |> assign(queryable: queryable)
    |> assign(budgets: budgets())
    |> assign(total_debits: total_debits)
    |> assign(total_credits: total_credits)
    |> assign(total_adjustments: total_adjustments)
    |> assign(now: NaiveDateTime.utc_now())
  end
end
