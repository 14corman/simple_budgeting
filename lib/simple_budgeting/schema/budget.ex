defmodule SimpleBudgeting.Schema.Budget do
  @moduledoc """
  Module for sites table in DB.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias SimpleBudgeting.Repo
  alias SimpleBudgeting.Schema

  @derive {Jason.Encoder, only: [:name, :description, :percentage, :amount, :open, :closed_on]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "budgets" do
    field :name, :string
    field :description, :string
    field :percentage, :float
    field :amount, Money.Ecto.Map.Type
    field :open, :boolean, default: true
    field :closed_on, :date

    belongs_to :account, Schema.Account

    has_many :transactions, Schema.Transaction

    timestamps()
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  def changeset(site, params \\ %{}) do
    site
    |> cast(params, [
      :name,
      :description,
      :percentage,
      :open,
      :closed_on,
      :amount,
      :account_id
    ])
    |> validate_required([
      :name,
      :open,
      :percentage,
      :amount,
      :account_id
    ])
    |> validate_number(:percentage, greater_than_or_equal_to: 0.0)
    |> validate_number(:percentage, less_than_or_equal_to: 100.0)
  end

  def reblance_budget(%__MODULE__{} = budget) do
    new_balance =
      budget
      |> SimpleBudgeting.Repo.preload(:transactions)
      |> Map.get(:transactions)
      |> Enum.filter(& &1.applied)
      |> Enum.map(fn transaction ->
        if transaction.type == "Debit" do
          Money.neg(transaction.amount)
        else
          transaction.amount
        end
      end)
      |> Enum.reduce(Money.new(0), &Money.add(&1, &2))

    budget
    |> changeset(%{amount: new_balance})
    |> SimpleBudgeting.Repo.update!()
  end

  def get_monthly_average_over_timeframe(budget, days, debit_credit) do
    start_date = days |> Enum.reverse() |> List.first()
    end_date = days |> List.first()

    from(
      budget in __MODULE__,
      inner_join: transactions in assoc(budget, :transactions),
      where: budget.id == ^budget.id and
        transactions.date_taken >= ^start_date and
        transactions.date_taken <= ^end_date and
        transactions.type == ^debit_credit and
        transactions.applied,
      select: {transactions.date_taken, transactions.amount},
      order_by: [desc: transactions.date_taken]
    )
    |> SimpleBudgeting.Repo.all()
    |> Enum.map(fn
      {date, money} -> {Date.new!(date.year, date.month, 1), money}
    end)
    |> Enum.group_by(& elem(&1, 0))
    |> Enum.map(fn {date, row} ->
      amount =
        row
        |> Enum.map(&elem(&1, 1))
        |> Enum.reduce(&Money.add/2)

      {date, amount}
    end)
    |> Enum.sort_by(fn {date, _} -> date end, {:asc, Date})
  end

  def get_amount_over_timeframe(budget, days) do
    start_date = days |> Enum.reverse() |> List.first()
    end_date = days |> List.first()

    transactions =
      from(
        budget in __MODULE__,
        inner_join: transactions in assoc(budget, :transactions),
        where: budget.id == ^budget.id and
          transactions.date_taken >= ^start_date and
          transactions.date_taken <= ^end_date and
          transactions.applied,
        select: {transactions.date_taken, transactions.amount, transactions.type},
        order_by: [desc: transactions.date_taken]
      )
      |> SimpleBudgeting.Repo.all()
      |> Enum.map(fn
        {date, money, "Debit"} -> {date, money}
        {date, money, "Credit"} -> {date, Money.neg(money)}
      end)
      |> Enum.group_by(& elem(&1, 0))
      |> Enum.map(fn {key, values} ->
        {
          key,
          Enum.reduce(values, Money.new(0), fn {_, money}, acc -> Money.add(money, acc) end)
        }
      end)
      |> Map.new()

    Enum.reduce(days, {[], budget.amount}, fn day, {acc, budget_amount} ->
      amount =
        case Map.get(transactions, day) do
          nil -> budget_amount
          value -> Money.add(value, budget_amount)
        end

      {[amount | acc], amount}
    end)
    |> elem(0)
  end
end
