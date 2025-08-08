defmodule LeetcodeSpaced.Repo.Migrations.CreateReviews do
  use Ecto.Migration

  def change do
    create table(:reviews) do
      add :confidence, :integer
      add :reviewed_at, :utc_datetime
      add :next_review, :utc_datetime
      add :review_count, :integer
      add :user_id, references(:users, on_delete: :nothing)
      add :problem_id, references(:problems, on_delete: :nothing)
      add :list_id, references(:lists, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:reviews, [:user_id])
    create index(:reviews, [:problem_id])
    create index(:reviews, [:list_id])
  end
end
