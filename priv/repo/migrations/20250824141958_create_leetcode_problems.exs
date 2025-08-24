defmodule LeetcodeSpaced.Repo.Migrations.CreateLeetcodeProblems do
  use Ecto.Migration

  def change do
    create table(:leetcode_problems) do
      add :leetcode_id, :integer, null: false
      add :name, :string, null: false
      add :url, :string, null: false
      add :difficulty, :string, null: false
      add :is_premium, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:leetcode_problems, [:leetcode_id])
    create index(:leetcode_problems, [:difficulty])
    create index(:leetcode_problems, [:is_premium])
  end
end
