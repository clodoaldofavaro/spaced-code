defmodule LeetcodeSpaced.Repo.Migrations.UpdateReviewsListIdConstraint do
  use Ecto.Migration

  def change do
    # Drop the existing foreign key constraint
    drop constraint(:reviews, "reviews_list_id_fkey")
    
    # Add the new foreign key constraint with cascade delete
    alter table(:reviews) do
      modify :list_id, references(:lists, on_delete: :delete_all)
    end
  end
end
