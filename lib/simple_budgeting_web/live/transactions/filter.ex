defmodule SimpleBudgetingWeb.Transactions.Filter do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  embedded_schema do
    field :page, :integer, default: 1
    field :term, :string
    field :location, :string
    field :month, :string
    field :year, :string
    field :budget, :string
    field :applied, :string
    field :receipt_code, :string
  end

  def changeset(filter, attrs) do
    filter
    |> cast(clean(attrs), [
      :term,
      :page,
      :location,
      :month,
      :year,
      :budget,
      :applied,
      :receipt_code
    ])
  end

  def to_keyword_list(filter) do
    [
      {:term, filter.term || ""},
      {:location, filter.location || ""},
      {:month, filter.month || ""},
      {:year, filter.year || ""},
      {:budget, filter.budget || ""},
      {:applied, filter.applied || ""},
      {:receipt_code, filter.receipt_code || ""}
    ]
  end

  defp clean(attrs) do
    attrs
    |> Enum.reduce(%{}, fn
      {_, ""}, accu -> accu
      {k, v}, accu -> Map.put(accu, k, v)
    end)
  end

  def apply_filter(queryable, %__MODULE__{} = filter) do
    filter
    |> Map.to_list()
    |> Enum.reduce(queryable, fn
      {:__struct__, _}, queryable ->
        queryable

      {:page, _}, queryable ->
        queryable

      {_, nil}, queryable ->
        queryable

      {:term, term}, queryable ->
        amount = String.replace(term, ".", "")

        queryable
        |> where(
          [transactions: t, rst_combined_amount_subquery: rst],
          ilike(type(t.description, :string), ^"%#{term}%") or
          ilike(type(fragment("(?->?)", t.amount, "amount"), :string), ^"%#{amount}%") or
          ilike(type(fragment("(?->?)", rst.combined_amounts, "amount"), :string), ^"%#{amount}%")
        )

      {:receipt_code, receipt_code}, queryable ->
        queryable
        |> where(
          [receipt_sources: r],
          ilike(type(r.name, :string), ^"%#{receipt_code}%")
        )

      {:budget, budget}, queryable ->
        queryable
        |> where(
          [budgets: b],
          ilike(type(b.name, :string), ^"%#{budget}%")
        )

      {:location, location}, queryable ->
        queryable
        |> where(
          [locations: l],
          ilike(type(l.name, :string), ^"%#{location}%")
        )

      {:applied, applied}, queryable ->
        case applied do
          "Yes" ->
            queryable
            |> where([transactions: t], t.applied)

          "No" ->
            queryable
            |> where([transactions: t], not t.applied)

          _ ->
            queryable
        end

      {:year, year}, queryable ->
        {year, _} = Integer.parse(year)

        queryable
        |> where(
          [transactions: t],
          fragment(
            "CAST(EXTRACT(YEAR FROM ?) AS INT) = CAST(? AS INT) OR CAST(? AS INT) IS NULL",
            t.date_taken,
            ^year,
            ^year
          )
        )

      {:month, month}, queryable ->
        month_num =
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

        if month_num == -1 do
          queryable
        else
          queryable
          |> where(
            [transactions: t],
            fragment("EXTRACT(MONTH FROM ?)::int = ?", t.date_taken, ^month_num)
          )
        end
    end)
  end
end
