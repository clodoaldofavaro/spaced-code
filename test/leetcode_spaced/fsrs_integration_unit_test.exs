defmodule LeetcodeSpaced.FsrsIntegrationUnitTest do
  use ExUnit.Case, async: true
  
  alias LeetcodeSpaced.FsrsIntegration

  describe "valid_rating?/1" do
    test "returns true for valid FSRS ratings" do
      assert FsrsIntegration.valid_rating?(:again) == true
      assert FsrsIntegration.valid_rating?(:hard) == true
      assert FsrsIntegration.valid_rating?(:good) == true
      assert FsrsIntegration.valid_rating?(:easy) == true
    end

    test "returns false for invalid ratings" do
      assert FsrsIntegration.valid_rating?(:invalid) == false
      assert FsrsIntegration.valid_rating?("good") == false
      assert FsrsIntegration.valid_rating?(1) == false
      assert FsrsIntegration.valid_rating?(nil) == false
    end
  end

  describe "get_scheduler/0" do
    test "returns an FSRS scheduler with correct settings" do
      scheduler = FsrsIntegration.get_scheduler()

      assert scheduler.desired_retention == 0.9
      assert scheduler.enable_fuzzing == true
      assert scheduler.maximum_interval == 36500
    end
  end

  describe "review_card/2 error handling" do
    test "returns error for invalid rating" do
      # Create a minimal review struct without relying on DB
      review = %{
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

      result = FsrsIntegration.review_card(review, :invalid_rating)
      assert result == {:error, :invalid_rating}
    end
  end
end