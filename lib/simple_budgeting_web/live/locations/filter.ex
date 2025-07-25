defmodule SimpleBudgetingWeb.Locations.Filter do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  embedded_schema do
    field :page, :integer, default: 1
    field :location, :string
    field :month, :string
    field :year, :integer
  end

  def changeset(filter, attrs) do
    filter
    |> cast(clean(attrs), [
      :page,
      :location,
      :month,
      :year
    ])
  end

  def to_keyword_list(filter) do
    [
      {:location, filter.location || ""},
      {:month, filter.month || ""},
      {:year, filter.year || 0}
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

      {:location, location}, queryable ->
        queryable
        |> where(
          [locations: l],
          ilike(type(l.name, :string), ^"%#{location}%")
        )

      {:year, _}, queryable ->
        queryable

      {:month, _}, queryable ->
        queryable
    end)
  end
end
