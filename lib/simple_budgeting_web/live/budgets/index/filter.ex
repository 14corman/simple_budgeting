defmodule SimpleBudgetingWeb.Budgets.Index.Filter do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  embedded_schema do
    field :page, :integer, default: 1
    field :budget, :string
    field :start_date, :string
    field :end_date, :string
  end

  @spec changeset(
          {map(),
           %{
             optional(atom()) =>
               atom()
               | {:array | :assoc | :embed | :in | :map | :parameterized | :supertype | :try,
                  any()}
           }}
          | %{
              :__struct__ => atom() | %{:__changeset__ => any(), optional(any()) => any()},
              optional(atom()) => any()
            },
          any()
        ) :: Ecto.Changeset.t()
  def changeset(filter, attrs) do
    filter
    |> cast(clean(attrs), [
      :page,
      :start_date,
      :end_date,
      :budget
    ])
  end

  @spec to_keyword_list(any()) :: [{:budget, any()}, ...]
  def to_keyword_list(filter) do
    [
      {:budget, filter.budget || ""},
      {:start_date, filter.start_date || ""},
      {:end_date, filter.end_date || ""}
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

      {:start_date, _}, queryable ->
        queryable

      {:end_date, _}, queryable ->
        queryable

      {:budget, budget}, queryable ->
        queryable
        |> where(
          [budgets: b],
          ilike(type(b.name, :string), ^"%#{budget}%")
        )
    end)
  end
end
