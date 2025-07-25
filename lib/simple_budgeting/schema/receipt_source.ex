defmodule SimpleBudgeting.Schema.ReceiptSource do
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
  schema "receipt_sources" do
    field :name, :string
    field :description, :string

    has_many :receipt_source_transactions, Schema.ReceiptSource.Transaction

    timestamps()
  end

  def get_or_create_by(attrs) do
    case Repo.get_by(__MODULE__, attrs) do
      nil -> create(attrs)
      location -> {:ok, location}
    end
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
    |> validate_required(:name)
  end
end
