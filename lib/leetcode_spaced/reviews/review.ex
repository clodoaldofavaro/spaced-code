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

    # FSRS fields
    field :fsrs_state, :string, default: "learning"
    field :fsrs_step, :integer
    field :stability, :float
    field :difficulty, :float
    field :due, :utc_datetime
    field :last_review, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(review, attrs) do
    review
    |> cast(attrs, [
      :confidence, :reviewed_at, :next_review, :review_count,
      :user_id, :problem_id,
      :fsrs_state, :fsrs_step, :stability, :difficulty, :due, :last_review
    ])
    |> validate_required([:user_id, :problem_id])
    |> validate_inclusion(:fsrs_state, ["learning", "review", "relearning"])
  end
end
