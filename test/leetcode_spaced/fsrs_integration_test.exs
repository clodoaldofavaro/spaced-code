defmodule LeetcodeSpaced.FsrsIntegrationTest do
  use ExUnit.Case, async: true
  
  alias LeetcodeSpaced.FsrsIntegration
  alias LeetcodeSpaced.Reviews.Review

  describe "new_card/3" do
    test "creates a new FSRS card with correct initial state" do
      problem_id = 1
      user_id = 1
      list_id = 1

      card = FsrsIntegration.new_card(problem_id, user_id, list_id)

      assert card.problem_id == problem_id
      assert card.user_id == user_id  
      assert card.list_id == list_id
      assert card.fsrs_state == "learning"
      assert card.fsrs_step == 0
      assert is_nil(card.stability)
      assert is_nil(card.difficulty)
      assert card.review_count == 0
      assert %DateTime{} = card.due
      assert is_nil(card.last_review)
    end
  end

  describe "review_card/2" do
    test "processes first review with 'good' rating correctly" do
      review = %Review{
        problem_id: 1,
        user_id: 1,
        list_id: 1,
        fsrs_state: "learning",
        fsrs_step: 0,
        stability: nil,
        difficulty: nil,
        review_count: 0,
        due: DateTime.utc_now(),
        last_review: nil
      }

      result = FsrsIntegration.review_card(review, :good)

      assert {:ok, updated_review} = result
      assert updated_review.fsrs_state == "review"
      assert is_nil(updated_review.fsrs_step)
      assert is_float(updated_review.stability)
      assert updated_review.stability > 0
      assert is_float(updated_review.difficulty)
      assert updated_review.difficulty > 0
      assert updated_review.review_count == 1
      assert %DateTime{} = updated_review.due
      assert %DateTime{} = updated_review.last_review
      assert DateTime.compare(updated_review.due, DateTime.utc_now()) == :gt
    end

    test "processes 'again' rating correctly - should reset to learning" do
      review = %Review{
        problem_id: 1,
        user_id: 1,
        list_id: 1,
        fsrs_state: "review",
        fsrs_step: nil,
        stability: 5.0,
        difficulty: 4.0,
        review_count: 3,
        due: DateTime.utc_now(),
        last_review: DateTime.add(DateTime.utc_now(), -5, :day)
      }

      result = FsrsIntegration.review_card(review, :again)

      assert {:ok, updated_review} = result
      assert updated_review.fsrs_state == "relearning"
      assert updated_review.fsrs_step == 0
      assert is_float(updated_review.stability)
      assert is_float(updated_review.difficulty)
      assert updated_review.review_count == 4
      assert %DateTime{} = updated_review.due
      assert %DateTime{} = updated_review.last_review
    end

    test "processes 'hard' rating correctly" do
      review = %Review{
        problem_id: 1,
        user_id: 1,
        list_id: 1,
        fsrs_state: "review",
        fsrs_step: nil,
        stability: 10.0,
        difficulty: 5.0,
        review_count: 2,
        due: DateTime.utc_now(),
        last_review: DateTime.add(DateTime.utc_now(), -7, :day)
      }

      result = FsrsIntegration.review_card(review, :hard)

      assert {:ok, updated_review} = result
      assert updated_review.fsrs_state == "review"
      assert is_nil(updated_review.fsrs_step)
      assert is_float(updated_review.stability)
      assert is_float(updated_review.difficulty)
      # Hard rating should increase difficulty
      assert updated_review.difficulty >= review.difficulty
      assert updated_review.review_count == 3
    end

    test "processes 'easy' rating correctly" do
      review = %Review{
        problem_id: 1,
        user_id: 1,
        list_id: 1,
        fsrs_state: "review",
        fsrs_step: nil,
        stability: 8.0,
        difficulty: 6.0,
        review_count: 1,
        due: DateTime.utc_now(),
        last_review: DateTime.add(DateTime.utc_now(), -3, :day)
      }

      result = FsrsIntegration.review_card(review, :easy)

      assert {:ok, updated_review} = result
      assert updated_review.fsrs_state == "review"
      assert is_nil(updated_review.fsrs_step)
      assert is_float(updated_review.stability)
      assert is_float(updated_review.difficulty)
      # Easy rating should decrease difficulty
      assert updated_review.difficulty <= review.difficulty
      assert updated_review.review_count == 2
      # Easy should schedule further out
      assert DateTime.diff(updated_review.due, DateTime.utc_now(), :day) > 7
    end

    test "handles invalid rating" do
      review = %Review{
        problem_id: 1,
        user_id: 1,
        list_id: 1,
        fsrs_state: "learning",
        fsrs_step: 0,
        stability: nil,
        difficulty: nil,
        review_count: 0,
        due: DateTime.utc_now(),
        last_review: nil
      }

      result = FsrsIntegration.review_card(review, :invalid)

      assert {:error, :invalid_rating} = result
    end
  end

  describe "to_fsrs_card/1" do
    test "converts Review struct to ExFsrs card" do
      review = %Review{
        problem_id: 1,
        user_id: 1,
        list_id: 1,
        fsrs_state: "review",
        fsrs_step: nil,
        stability: 12.5,
        difficulty: 4.2,
        review_count: 3,
        due: ~U[2025-01-01 12:00:00Z],
        last_review: ~U[2024-12-25 12:00:00Z]
      }

      fsrs_card = FsrsIntegration.to_fsrs_card(review)

      assert fsrs_card.card_id == review.problem_id
      assert fsrs_card.state == :review
      assert fsrs_card.step == nil
      assert fsrs_card.stability == 12.5
      assert fsrs_card.difficulty == 4.2
      assert fsrs_card.due == ~U[2025-01-01 12:00:00Z]
      assert fsrs_card.last_review == ~U[2024-12-25 12:00:00Z]
    end

    test "converts learning state correctly" do
      review = %Review{
        problem_id: 2,
        user_id: 1,
        list_id: 1,
        fsrs_state: "learning",
        fsrs_step: 1,
        stability: nil,
        difficulty: nil,
        review_count: 0,
        due: DateTime.utc_now(),
        last_review: nil
      }

      fsrs_card = FsrsIntegration.to_fsrs_card(review)

      assert fsrs_card.state == :learning
      assert fsrs_card.step == 1
      assert is_nil(fsrs_card.stability)
      assert is_nil(fsrs_card.difficulty)
    end
  end

  describe "from_fsrs_card/3" do
    test "converts ExFsrs card back to Review attributes" do
      fsrs_card = ExFsrs.new(
        card_id: 1,
        state: :review,
        step: nil,
        stability: 15.3,
        difficulty: 3.8,
        due: ~U[2025-02-01 10:00:00Z],
        last_review: ~U[2025-01-15 10:00:00Z]
      )

      user_id = 5
      list_id = 10

      attrs = FsrsIntegration.from_fsrs_card(fsrs_card, user_id, list_id)

      assert attrs.problem_id == 1
      assert attrs.user_id == 5
      assert attrs.list_id == 10
      assert attrs.fsrs_state == "review"
      assert attrs.fsrs_step == nil
      assert attrs.stability == 15.3
      assert attrs.difficulty == 3.8
      assert attrs.due == ~U[2025-02-01 10:00:00Z]
      assert attrs.last_review == ~U[2025-01-15 10:00:00Z]
    end

    test "converts relearning state correctly" do
      fsrs_card = ExFsrs.new(
        card_id: 3,
        state: :relearning,
        step: 0,
        stability: 2.1,
        difficulty: 7.5,
        due: DateTime.utc_now(),
        last_review: DateTime.utc_now()
      )

      attrs = FsrsIntegration.from_fsrs_card(fsrs_card, 1, 1)

      assert attrs.fsrs_state == "relearning"
      assert attrs.fsrs_step == 0
    end
  end

  describe "get_due_problems/2" do
    test "returns problems that are due for review" do
      today = DateTime.utc_now()
      yesterday = DateTime.add(today, -1, :day)
      tomorrow = DateTime.add(today, 1, :day)

      due_review = %Review{
        problem_id: 1,
        user_id: 1,
        list_id: 1,
        due: yesterday,
        fsrs_state: "review"
      }

      not_due_review = %Review{
        problem_id: 2,
        user_id: 1,
        list_id: 1,
        due: tomorrow,
        fsrs_state: "review"
      }

      # This would be mocked in a real implementation
      # For now, we test the logic structure
      assert FsrsIntegration.is_due?(due_review) == true
      assert FsrsIntegration.is_due?(not_due_review) == false
    end
  end

  describe "calculate_retention/1" do
    test "calculates retrievability for a card" do
      review = %Review{
        stability: 10.0,
        last_review: DateTime.add(DateTime.utc_now(), -5, :day)
      }

      retrievability = FsrsIntegration.calculate_retention(review)

      assert is_float(retrievability)
      assert retrievability >= 0.0
      assert retrievability <= 1.0
    end

    test "returns 0 for cards never reviewed" do
      review = %Review{
        stability: nil,
        last_review: nil
      }

      retrievability = FsrsIntegration.calculate_retention(review)

      assert retrievability == 0.0
    end
  end
end