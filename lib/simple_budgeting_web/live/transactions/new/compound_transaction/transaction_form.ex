defmodule SimpleBudgetingWeb.Transactions.New.CompoundTransaction.TransactionForm do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  embedded_schema do
    field :description, :string, default: ""
    field :amount, Money.Ecto.Map.Type, default: Money.new(0)
    field :budget_id, :string
  end

  def changeset(filter, attrs) do
    filter
    |> cast(clean(attrs), [
      :description,
      :amount,
      :budget_id
    ])
    |> validate_required([
      :amount,
      :budget_id
    ])
    |> validate_string_number(:amount)
  end

  def to_keyword_list(filter) do
    [
      {:description, filter.description || ""},
      {:budget_id, filter.budget_id || ""},
      {:amount, filter.amount || Money.new(0)}
    ]
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
