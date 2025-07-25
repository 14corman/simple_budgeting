defmodule SimpleBudgetingWeb.Repo.Migrations.SetUpTables do
  use Ecto.Migration

  def change do
    create table(:locations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :description, :text, null: true
      timestamps()
    end

    create index(:locations, :name)

    create table(:receipt_sources, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :description, :text, null: true
      timestamps()
    end

    create index(:receipt_sources, :name)

    create table(:accounts, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :description, :text, null: true
      timestamps()
    end

    create index(:accounts, :name)

    create table(:budgets, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :description, :text, null: true
      add :percentage, :float, null: false
      add :amount, :map, null: false
      add :open, :boolean, null: false, default: true
      add :closed_on, :date, null: true

      add :account_id, references(:accounts, type: :uuid, on_delete: :restrict), null: false

      timestamps()
    end

    create index(:budgets, :name)

    create table(:receipt_source_transaction, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :identifier, :string, null: true
      add :receipt_image_name, :string, null: true

      add :receipt_source_id, references(:receipt_sources, type: :uuid, on_delete: :restrict), null: false

      timestamps()
    end

    create index(:receipt_source_transaction, :identifier)

    create table(:transactions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :description, :text, null: true
      add :type, :string, null: false
      add :amount, :map, null: false
      add :applied, :boolean, null: false, default: false
      add :date_taken, :date, null: false

      add :budget_id, references(:budgets, type: :uuid, on_delete: :restrict), null: false
      add :location_id, references(:locations, type: :uuid, on_delete: :restrict), null: false
      add :receipt_source_transaction_id, references(:receipt_source_transaction, type: :uuid, on_delete: :restrict), null: false

      timestamps()
    end
  end
end
