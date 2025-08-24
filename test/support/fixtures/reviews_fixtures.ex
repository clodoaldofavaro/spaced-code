defmodule LeetcodeSpaced.ReviewsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LeetcodeSpaced.Reviews` context.
  """

  @doc """
  Generate a review.
  """
  def review_fixture(attrs \\ %{}) do
    {:ok, review} =
      attrs
      |> Enum.into(%{
        problem_id: 1,
        user_id: 1,
        fsrs_state: "learning",
        fsrs_step: 0,
        stability: 2.5,
        difficulty: 5.0,
        due: ~U[2025-08-18 12:00:00Z],
        last_review: ~U[2025-08-18 10:00:00Z],
        review_count: 1,
        reviewed_at: ~U[2025-08-18 10:00:00Z],
        next_review: ~U[2025-08-18 12:00:00Z],
        confidence: 42
      })
      |> LeetcodeSpaced.Reviews.create_review()

    review
  end
end
