defmodule LeetcodeSpaced.Reviews.Review do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reviews" do
    field :confidence, :integer
    field :reviewed_at, :utc_datetime
    field :next_review, :utc_datetime
    field :review_count, :integer
    field :user_id, :id
    field :problem_id, :id
    field :list_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(review, attrs) do
    review
    |> cast(attrs, [:confidence, :reviewed_at, :next_review, :review_count])
    |> validate_required([:confidence, :reviewed_at, :next_review, :review_count])
  end
end
