defmodule SimpleBudgeting.Schema.Transaction do
  @moduledoc """
  Module for sites table in DB.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias SimpleBudgeting.Repo
  alias SimpleBudgeting.Schema

  @derive {Jason.Encoder, only: [:type, :description, :amount, :applied, :date_taken]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transactions" do
    field :description, :string
    field :type, :string
    field :amount, Money.Ecto.Map.Type
    field :applied, :boolean, default: false
    field :date_taken, :date

    belongs_to :receipt_source_transaction, Schema.ReceiptSource.Transaction
    belongs_to :budget, Schema.Budget
    belongs_to :location, Schema.Location

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
      :description,
      :type,
      :amount,
      :applied,
      :date_taken,
      :budget_id,
      :location_id,
      :receipt_source_transaction_id
    ])
    |> validate_required([
      :type,
      :amount,
      :applied,
      :date_taken,
      :budget_id,
      :location_id
    ])
    |> validate_amount()
  end

  def insert_transaction(%__MODULE__{} = transaction, money_attrs) do
    SimpleBudgeting.Repo.transaction(fn ->
      receipt_source_transaction =
        %SimpleBudgeting.Schema.ReceiptSource.Transaction{}
        |> SimpleBudgeting.Schema.ReceiptSource.Transaction.changeset(money_attrs)
        |> SimpleBudgeting.Repo.insert!()

      money_attrs
      |> Map.put("receipt_source_transaction_id", receipt_source_transaction.id)
      |> complete_insert_transaction(transaction)
    end)
  end

  def insert_transaction(%__MODULE__{} = transaction, receipt_source_transaction, money_attrs) do
    SimpleBudgeting.Repo.transaction(fn ->
      money_attrs
      |> Map.put("receipt_source_transaction_id", receipt_source_transaction.id)
      |> complete_insert_transaction(transaction)
    end)
  end

  def remove_transaction(%__MODULE__{} = transaction) do
    SimpleBudgeting.Repo.transaction(fn ->
      receipt_source_transaction =
        transaction
        |> SimpleBudgeting.Repo.preload(:receipt_source_transaction)
        |> Map.get(:receipt_source_transaction)

      if transaction.applied do
        budget =
          transaction
          |> SimpleBudgeting.Repo.preload(:budget)
          |> Map.get(:budget)

        if transaction.type == "Debit" do
          budget
          |> SimpleBudgeting.Schema.Budget.changeset(%{
            amount: Money.add(budget.amount, transaction.amount)
          })
          |> SimpleBudgeting.Repo.update!()
        else
          budget
          |> SimpleBudgeting.Schema.Budget.changeset(%{
            amount: Money.subtract(budget.amount, transaction.amount)
          })
          |> SimpleBudgeting.Repo.update!()
        end
      end

      SimpleBudgeting.Repo.delete!(transaction)

      no_transactions? =
        receipt_source_transaction
        |> SimpleBudgeting.Repo.preload(:transactions, force: true)
        |> Map.get(:transactions)
        |> Enum.empty?()

      if no_transactions? do
        SimpleBudgeting.Repo.delete!(receipt_source_transaction)
        true
      else
        false
      end
    end)
  end

  def apply_transaction(%__MODULE__{} = transaction) do
    SimpleBudgeting.Repo.transaction(fn ->
      budget =
        transaction
        |> SimpleBudgeting.Repo.preload(:budget)
        |> Map.get(:budget)

      if transaction.type == "Debit" do
        budget
        |> SimpleBudgeting.Schema.Budget.changeset(%{
          amount: Money.subtract(budget.amount, transaction.amount)
        })
        |> SimpleBudgeting.Repo.update!()
      else
        budget
        |> SimpleBudgeting.Schema.Budget.changeset(%{
          amount: Money.add(budget.amount, transaction.amount)
        })
        |> SimpleBudgeting.Repo.update!()
      end
    end)
  end

  def undo_transaction(%__MODULE__{} = transaction) do
    SimpleBudgeting.Repo.transaction(fn ->
      budget =
        transaction
        |> SimpleBudgeting.Repo.preload(:budget)
        |> Map.get(:budget)

      if transaction.type == "Debit" do
        budget
        |> SimpleBudgeting.Schema.Budget.changeset(%{
          amount: Money.add(budget.amount, transaction.amount)
        })
        |> SimpleBudgeting.Repo.update!()
      else
        budget
        |> SimpleBudgeting.Schema.Budget.changeset(%{
          amount: Money.subtract(budget.amount, transaction.amount)
        })
        |> SimpleBudgeting.Repo.update!()
      end
    end)
  end

  defp complete_insert_transaction(money_attrs, %__MODULE__{} = transaction) do
    transaction =
      transaction
      |> changeset(money_attrs)
      |> SimpleBudgeting.Repo.insert!()

    if transaction.applied do
      budget =
        transaction
        |> SimpleBudgeting.Repo.preload(:budget)
        |> Map.get(:budget)

      if transaction.type == "Debit" do
        budget
        |> SimpleBudgeting.Schema.Budget.changeset(%{
          amount: Money.subtract(budget.amount, transaction.amount)
        })
        |> SimpleBudgeting.Repo.update!()
      else
        budget
        |> SimpleBudgeting.Schema.Budget.changeset(%{
          amount: Money.add(budget.amount, transaction.amount)
        })
        |> SimpleBudgeting.Repo.update!()
      end
    end
  end

  defp validate_amount(changeset) do
    money = get_field(changeset, :amount, Money.new(0))
    amount = money.amount

    if amount < 1 do
      add_error(changeset, :amount, "must be greater than #{Money.new(0)}",
        validation: "too small"
      )
    else
      changeset
    end
  end
end
