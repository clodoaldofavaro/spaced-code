defmodule LeetcodeSpaced.Repo.Migrations.CreateListsProblems do
  use Ecto.Migration

  def change do
    create table(:lists_problems, primary_key: false) do
      add :list_id, references(:lists, on_delete: :delete_all), null: false
      add :problem_id, references(:problems, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:lists_problems, [:list_id, :problem_id])
    create index(:lists_problems, [:problem_id])
  end
end
