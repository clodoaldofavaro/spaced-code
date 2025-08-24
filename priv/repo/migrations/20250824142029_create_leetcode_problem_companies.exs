defmodule LeetcodeSpaced.Repo.Migrations.CreateLeetcodeProblemCompanies do
  use Ecto.Migration

  def change do
    create table(:leetcode_problem_companies, primary_key: false) do
      add :leetcode_problem_id, references(:leetcode_problems, on_delete: :delete_all), null: false
      add :company_id, references(:companies, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:leetcode_problem_companies, [:leetcode_problem_id, :company_id])
    create index(:leetcode_problem_companies, [:leetcode_problem_id])
    create index(:leetcode_problem_companies, [:company_id])
  end
end
