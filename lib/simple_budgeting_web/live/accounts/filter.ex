defmodule SimpleBudgetingWeb.Accounts.Filter do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  embedded_schema do
    field :page, :integer, default: 1
    field :term, :string
  end

  def changeset(filter, attrs) do
    filter
    |> cast(clean(attrs), [
      :term,
      :page
    ])
  end

  def to_keyword_list(filter) do
    [
      {:term, filter.term || ""}
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

      {:term, term}, queryable ->
        queryable
        |> where(
          [accounts: a],
          ilike(type(a.name, :string), ^"%#{term}%")
          # or
          # ilike(type(i.collection_number, :string), ^"%#{term}%") or
          # ilike(type(s.sample_id, :string), ^"%#{term}%") or
          # ilike(type(s.sample_family_id, :string), ^"%#{term}%")
        )
    end)
  end
end
