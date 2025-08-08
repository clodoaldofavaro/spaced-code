defmodule LeetcodeSpaced.ReviewsTest do
  use LeetcodeSpaced.DataCase

  alias LeetcodeSpaced.Reviews

  describe "reviews" do
    alias LeetcodeSpaced.Reviews.Review

    import LeetcodeSpaced.ReviewsFixtures

    @invalid_attrs %{confidence: nil, reviewed_at: nil, next_review: nil, review_count: nil}

    test "list_reviews/0 returns all reviews" do
      review = review_fixture()
      assert Reviews.list_reviews() == [review]
    end

    test "get_review!/1 returns the review with given id" do
      review = review_fixture()
      assert Reviews.get_review!(review.id) == review
    end

    test "create_review/1 with valid data creates a review" do
      valid_attrs = %{
        confidence: 42,
        reviewed_at: ~U[2025-08-07 16:00:00Z],
        next_review: ~U[2025-08-07 16:00:00Z],
        review_count: 42
      }

      assert {:ok, %Review{} = review} = Reviews.create_review(valid_attrs)
      assert review.confidence == 42
      assert review.reviewed_at == ~U[2025-08-07 16:00:00Z]
      assert review.next_review == ~U[2025-08-07 16:00:00Z]
      assert review.review_count == 42
    end

    test "create_review/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Reviews.create_review(@invalid_attrs)
    end

    test "update_review/2 with valid data updates the review" do
      review = review_fixture()

      update_attrs = %{
        confidence: 43,
        reviewed_at: ~U[2025-08-08 16:00:00Z],
        next_review: ~U[2025-08-08 16:00:00Z],
        review_count: 43
      }

      assert {:ok, %Review{} = review} = Reviews.update_review(review, update_attrs)
      assert review.confidence == 43
      assert review.reviewed_at == ~U[2025-08-08 16:00:00Z]
      assert review.next_review == ~U[2025-08-08 16:00:00Z]
      assert review.review_count == 43
    end

    test "update_review/2 with invalid data returns error changeset" do
      review = review_fixture()
      assert {:error, %Ecto.Changeset{}} = Reviews.update_review(review, @invalid_attrs)
      assert review == Reviews.get_review!(review.id)
    end

    test "delete_review/1 deletes the review" do
      review = review_fixture()
      assert {:ok, %Review{}} = Reviews.delete_review(review)
      assert_raise Ecto.NoResultsError, fn -> Reviews.get_review!(review.id) end
    end

    test "change_review/1 returns a review changeset" do
      review = review_fixture()
      assert %Ecto.Changeset{} = Reviews.change_review(review)
    end
  end
end
