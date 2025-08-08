defmodule LeetcodeSpaced.Repo.Migrations.UpdateProblemsTableGeneric do
  use Ecto.Migration

  def change do
    alter table(:problems) do
      add :platform, :string
      add :platform_id, :string
      add :description, :text
      add :custom_problem, :boolean, default: false
    end

    rename table(:problems), :leetcode_url, to: :url
    rename table(:problems), :leetcode_id, to: :old_leetcode_id

    create unique_index(:problems, [:platform, :platform_id])
    drop unique_index(:problems, [:leetcode_id])
  end
end
