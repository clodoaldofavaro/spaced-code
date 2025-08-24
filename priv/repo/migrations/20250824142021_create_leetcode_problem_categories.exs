defmodule LeetcodeSpaced.Repo.Migrations.CreateLeetcodeProblemCategories do
  use Ecto.Migration

  def change do
    create table(:leetcode_problem_categories, primary_key: false) do
      add :leetcode_problem_id, references(:leetcode_problems, on_delete: :delete_all), null: false
      add :category_id, references(:categories, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:leetcode_problem_categories, [:leetcode_problem_id, :category_id])
    create index(:leetcode_problem_categories, [:leetcode_problem_id])
    create index(:leetcode_problem_categories, [:category_id])
  end
end
