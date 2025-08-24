defmodule LeetcodeSpaced.Repo.Migrations.AddFsrsFieldsToReviews do
  use Ecto.Migration

  def change do
    alter table(:reviews) do
      add :fsrs_state, :string, default: "learning"
      add :fsrs_step, :integer
      add :stability, :float
      add :difficulty, :float
      add :due, :utc_datetime
      add :last_review, :utc_datetime
    end

    # Create index for efficient queries
    create index(:reviews, [:fsrs_state])
    create index(:reviews, [:user_id, :list_id, :due])
    create index(:reviews, [:user_id, :list_id, :next_review])
  end
end
