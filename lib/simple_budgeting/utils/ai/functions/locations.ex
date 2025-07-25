defmodule SimpleBudgeting.Utils.AI.Functions.Locations do
  @moduledoc false

  import Ecto.Query, warn: false

  alias LangChain.Function
  alias LangChain.FunctionParam
  alias SimpleBudgeting.Repo

  def get_functions!() do
    [
      new_get_locations!()
    ]
  end

  defp new_get_locations!() do
    Function.new!(%{
      name: "get_locations",
      display_text: "Get locations",
      description: "Get a list of locations",
      function: &execute_get_locations/2
    })
  end

  defp execute_get_locations(_arguments, _context) do
    headers = "name\tdescription\n"
    locations =
      from(locations in SimpleBudgeting.Schema.Location)
      |> Repo.all()
      |> Enum.map(fn location ->
        "#{location.name}\t#{location.description}"
      end)
      |> Enum.join("\n")

    {:ok, headers <> locations}
  end
end
