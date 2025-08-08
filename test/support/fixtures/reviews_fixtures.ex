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
        confidence: 42,
        next_review: ~U[2025-08-07 16:00:00Z],
        review_count: 42,
        reviewed_at: ~U[2025-08-07 16:00:00Z]
      })
      |> LeetcodeSpaced.Reviews.create_review()

    review
  end
end
