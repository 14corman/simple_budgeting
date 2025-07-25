defmodule SimpleBudgetingWeb.ReceiptSources.Filter do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  embedded_schema do
    field :page, :integer, default: 1
    field :receipt_source, :string
  end

  def changeset(filter, attrs) do
    filter
    |> cast(clean(attrs), [
      :page,
      :receipt_source
    ])
  end

  def to_keyword_list(filter) do
    [
      {:receipt_source, filter.receipt_source || ""}
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

      {:receipt_source, receipt_source}, queryable ->
        queryable
        |> where(
          [receipt_sources: r],
          ilike(type(r.name, :string), ^"%#{receipt_source}%")
        )
    end)
  end
end
