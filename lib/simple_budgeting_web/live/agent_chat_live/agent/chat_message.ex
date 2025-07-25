defmodule SimpleBudgetingWeb.AgentChatLive.Agent.ChatMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :role, Ecto.Enum,
      values: [:system, :user, :assistant, :tool],
      default: :user

    field :hidden, :boolean, default: true
    field :content, :string
    field :tool_calls, {:array, :map}, default: []
    field :tool_results, {:array, :map}, default: []
  end

  @type t :: %__MODULE__{}

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:role, :hidden, :content])
    |> common_validations()
  end

  @doc false
  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:role, :hidden, :content])
    |> common_validations()
  end

  defp common_validations(changeset) do
    changeset
    |> validate_required([:role, :hidden, :content])
  end

  def new(params) do
    params
    |> create_changeset()
    |> Map.put(:action, :insert)
    |> apply_action(:insert)
  end
end
