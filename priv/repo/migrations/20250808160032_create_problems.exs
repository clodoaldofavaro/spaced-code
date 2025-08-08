defmodule LeetcodeSpaced.Repo.Migrations.CreateProblems do
  use Ecto.Migration

  def change do
    create table(:problems) do
      add :title, :string
      add :leetcode_url, :string
      add :leetcode_id, :integer
      add :difficulty, :string
      add :topics, {:array, :string}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:problems, [:leetcode_id])
  end
end
