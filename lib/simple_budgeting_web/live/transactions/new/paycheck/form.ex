defmodule SimpleBudgetingWeb.Transactions.New.Paycheck.Form do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  embedded_schema do
    field :location_id, :string
    field :leftover_budget_id, :string
    field :receipt_source_id, :string
    field :description, :string, default: ""
    field :paycheck_amount, Money.Ecto.Map.Type, default: Money.new(0)
    field :applied, :string, default: "false"
    field :date_taken, :date, default: Date.utc_today()
  end

  def changeset(filter, attrs) do
    filter
    |> cast(clean(attrs), [
      :location_id,
      :leftover_budget_id,
      :receipt_source_id,
      :description,
      :paycheck_amount,
      :applied,
      :date_taken
    ])
    |> validate_required([
      :location_id,
      :leftover_budget_id,
      :receipt_source_id,
      :paycheck_amount,
      :applied,
      :date_taken
    ])
    |> validate_string_number(:paycheck_amount)
  end

  defp validate_string_number(changeset, key) do
    money = get_field(changeset, key, Money.new(0))
    amount = money.amount

    if amount < 1 do
      add_error(changeset, key, "must be greater than #{Money.new(0)}", validation: "too small")
    else
      changeset
    end
  end

  defp clean(attrs) do
    attrs
    |> Enum.reduce(%{}, fn
      {_, ""}, accu -> accu
      {k, v}, accu -> Map.put(accu, k, v)
    end)
  end
end
