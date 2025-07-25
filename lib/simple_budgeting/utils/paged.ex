defmodule SimpleBudgeting.Utils.Paged do
  @moduledoc """
  Provides pagination functions
  """

  defstruct total_count: 0,
            shown_count: 0,
            records: [],
            starting_at: 0,
            ending_at: 0

  import Ecto.Query, warn: false

  @doc """
  Build a paged objected from a queryable expression
  """
  def paginate(queryable, opts \\ [])

  def paginate(nil, _opts) do
    %__MODULE__{}
  end

  def paginate(queryable, opts) do
    with pagination_opts <- pagination_opts(opts),
         paged_query <- paged_query(queryable, pagination_opts),
         repo <- opts[:repo] do
      try do
        prefix = Keyword.fetch!(pagination_opts, :prefix)
        page = Keyword.fetch!(pagination_opts, :page)
        per_page = Keyword.fetch!(pagination_opts, :per_page)
        offset = calculated_offset(page, per_page)

        records =
          paged_query
          |> repo.all(prefix: prefix)
          |> repo.preload(opts[:preload] || [], prefix: prefix, force: true)

        shown_count = length(records)

        %__MODULE__{
          total_count: total_count(queryable, repo, prefix: prefix),
          shown_count: shown_count,
          records: records,
          starting_at: offset + 1,
          ending_at: offset + shown_count
        }
      rescue
        _error ->
          %__MODULE__{}
      end
    end
  end

  defp total_count(queryable, repo, prefix: prefix) do
    queryable = %{queryable | order_bys: []}

    from(
      a in subquery(queryable),
      select: count(1)
    )
    |> repo.one(prefix: prefix)
  end

  @doc """
  Paginate a querable expression
  """
  def paged_query(queryable, prefix: _prefix, page: page, per_page: per_page) do
    queryable
    |> limit(^per_page)
    |> offset(^calculated_offset(page, per_page))
  end

  @default_opts [
    page: 1,
    per_page: 5,
    prefix: nil
  ]

  defp pagination_opts(opts) do
    Keyword.merge(@default_opts, opts)
    |> Keyword.take([:page, :per_page, :prefix])
  end

  defp calculated_offset(page, per_page) do
    (page - 1) * per_page
  end
end
