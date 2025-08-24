defmodule LeetcodeSpaced.Repo.Migrations.RemoveListIdFromReviews do
  use Ecto.Migration

  def change do
    # Remove the list_id column from reviews table
    alter table(:reviews) do
      remove :list_id
    end
  end
end
