defmodule SimpleBudgetingWeb.Transactions.Show.HeaderForm do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  embedded_schema do
    field :location_id, :string
    field :receipt_source_id, :string
    field :identifier, :string
    field :type, :string, default: "Debit"
  end

  def changeset(filter, attrs \\ %{}) do
    filter
    |> cast(clean(attrs), [
      :location_id,
      :receipt_source_id,
      :identifier,
      :type
    ])
    |> validate_required([
      :location_id,
      :receipt_source_id,
      :type
    ])
  end

  def to_keyword_list(filter) do
    [
      {:location_id, filter.location_id || ""},
      {:receipt_source_id, filter.receipt_source_id || ""},
      {:identifier, filter.identifier || ""},
      {:type, filter.budget || "Debit"}
    ]
  end

  defp clean(attrs) do
    attrs
    |> Enum.reduce(%{}, fn
      {_, ""}, accu -> accu
      {k, v}, accu -> Map.put(accu, k, v)
    end)
  end
end
