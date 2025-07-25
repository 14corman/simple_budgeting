defmodule SimpleBudgeting.Schema.ReceiptSource.Transaction do
  @moduledoc """
  Module for sites table in DB.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias SimpleBudgeting.Repo
  alias SimpleBudgeting.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "receipt_source_transaction" do
    field :identifier, :string
    field :receipt_image_name, :string

    belongs_to :receipt_source, Schema.ReceiptSource

    has_many :transactions, Schema.Transaction, foreign_key: :receipt_source_transaction_id

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
      :identifier,
      :receipt_image_name,
      :receipt_source_id
    ])
    |> validate_required([
      :receipt_source_id
    ])
  end
end
