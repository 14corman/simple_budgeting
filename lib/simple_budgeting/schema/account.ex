defmodule SimpleBudgeting.Schema.Account do
  @moduledoc """
  Module for sites table in DB.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias SimpleBudgeting.Repo
  alias SimpleBudgeting.Schema

  @derive {Jason.Encoder, only: [:name, :description]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field :name, :string
    field :description, :string

    has_many :budgets, Schema.Budget

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
      :description
    ])
    |> validate_required([
      :name
    ])
  end

  def get_amount_over_timeframe(account, days) do
    account = SimpleBudgeting.Repo.preload(account, :budgets)
    account.budgets
    |> Enum.map(& Schema.Budget.get_amount_over_timeframe(&1, days))
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(fn amounts -> Enum.reduce(amounts, Money.new(0), & Money.add(&1, &2)) end)
  end
end
