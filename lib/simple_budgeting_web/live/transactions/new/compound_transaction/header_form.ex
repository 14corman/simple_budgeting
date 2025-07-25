defmodule SimpleBudgetingWeb.Transactions.New.CompoundTransaction.HeaderForm do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  embedded_schema do
    field :location_id, :string
    field :receipt_source_id, :string
    field :identifier, :string
    field :type, :string, default: "Debit"
    field :number_transactions, :integer, default: 1
    field :applied, :string, default: "false"
    field :date_taken, :date, default: Date.utc_today()
  end

  def changeset(filter, attrs) do
    filter
    |> cast(clean(attrs), [
      :location_id,
      :receipt_source_id,
      :identifier,
      :type,
      :number_transactions,
      :applied,
      :date_taken
    ])
    |> validate_required([
      :location_id,
      :receipt_source_id,
      :type,
      :number_transactions,
      :applied,
      :date_taken
    ])
    |> validate_number(:number_transactions, greater_than_or_equal_to: 0)
  end

  def to_keyword_list(filter) do
    [
      {:location_id, filter.location_id || ""},
      {:receipt_source_id, filter.receipt_source_id || ""},
      {:identifier, filter.identifier || ""},
      {:type, filter.budget || "Debit"},
      {:number_transactions, filter.number_transactions || 1},
      {:applied, filter.applied || "false"},
      {:date_taken, filter.date_taken || Date.utc_today()}
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
