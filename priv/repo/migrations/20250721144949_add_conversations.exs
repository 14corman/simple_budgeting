defmodule SimpleBudgeting.Repo.Migrations.AddConversations do
  use Ecto.Migration

  def change do
    create table(:conversations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :model, :string
      add :temperature, :float, default: 1.0
      add :frequency_penalty, :float, default: 0.0

      timestamps()
    end

    create index(:conversations, [:name])

    create table(:messages, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :conversation_id, references(:conversations, type: :uuid, on_delete: :delete_all), null: false
      add :role, :string
      add :content, :text
      add :edited, :boolean, default: false, null: false
      add :status, :string

      timestamps()
    end

    create index(:messages, [:conversation_id])
    create index(:messages, [:status])
  end
end
