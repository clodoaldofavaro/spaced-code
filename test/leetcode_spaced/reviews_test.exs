defmodule LeetcodeSpaced.ReviewsTest do
  use LeetcodeSpaced.DataCase

  alias LeetcodeSpaced.Reviews
  alias LeetcodeSpaced.Reviews.Review

  describe "reviews" do
    import LeetcodeSpaced.ReviewsFixtures

    @valid_attrs %{
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
      next_review: ~U[2025-08-18 12:00:00Z]
    }
    @update_attrs %{
      fsrs_state: "review",
      fsrs_step: 1,
      stability: 3.0,
      difficulty: 4.5,
      review_count: 2
    }
    @invalid_attrs %{problem_id: nil, user_id: nil}

    test "list_reviews/0 returns all reviews" do
      review = review_fixture()
      assert Reviews.list_reviews() == [review]
    end

    test "get_review!/1 returns the review with given id" do
      review = review_fixture()
      assert Reviews.get_review!(review.id) == review
    end

    test "create_review/1 with valid data creates a review" do
      assert {:ok, %Review{} = review} = Reviews.create_review(@valid_attrs)
      assert review.problem_id == 1
      assert review.user_id == 1
      assert review.fsrs_state == "learning"
      assert review.fsrs_step == 0
      assert review.stability == 2.5
      assert review.difficulty == 5.0
      assert review.review_count == 1
    end

    test "create_review/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Reviews.create_review(@invalid_attrs)
    end

    test "update_review/2 with valid data updates the review" do
      review = review_fixture()

      assert {:ok, %Review{} = review} = Reviews.update_review(review, @update_attrs)
      assert review.fsrs_state == "review"
      assert review.fsrs_step == 1
      assert review.stability == 3.0
      assert review.difficulty == 4.5
      assert review.review_count == 2
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

  describe "get_due_problems_for_list/2" do
    import LeetcodeSpaced.StudyFixtures
    import LeetcodeSpaced.AccountsFixtures

    test "returns problems due for review" do
      user = user_fixture()
      list = list_fixture(%{user_id: user.id})
      problem1 = problem_fixture()
      problem2 = problem_fixture()

      # Add problems to list
      LeetcodeSpaced.Study.add_problem_to_list(list.id, problem1.id)
      LeetcodeSpaced.Study.add_problem_to_list(list.id, problem2.id)

      # Create a review for problem1 that's due
      review_fixture(%{
        problem_id: problem1.id,
        user_id: user.id,
        list_id: list.id,
        # Due 1 hour ago
        due: DateTime.add(DateTime.utc_now(), -1, :hour)
      })

      # Create a review for problem2 that's not due yet
      review_fixture(%{
        problem_id: problem2.id,
        user_id: user.id,
        list_id: list.id,
        # Due in 1 hour
        due: DateTime.add(DateTime.utc_now(), 1, :hour)
      })

      due_problems = Reviews.get_due_problems_for_list(list.id, user.id)

      assert length(due_problems) == 1
      assert Enum.find(due_problems, fn p -> p.id == problem1.id end)
      refute Enum.find(due_problems, fn p -> p.id == problem2.id end)
    end

    test "returns problems with no reviews as due" do
      user = user_fixture()
      list = list_fixture(%{user_id: user.id})
      problem = problem_fixture()

      # Add problem to list but create no review
      LeetcodeSpaced.Study.add_problem_to_list(list.id, problem.id)

      due_problems = Reviews.get_due_problems_for_list(list.id, user.id)

      assert length(due_problems) == 1
      assert Enum.find(due_problems, fn p -> p.id == problem.id end)
    end

    test "orders problems by due date" do
      user = user_fixture()
      list = list_fixture(%{user_id: user.id})
      problem1 = problem_fixture()
      problem2 = problem_fixture()

      # Add problems to list
      LeetcodeSpaced.Study.add_problem_to_list(list.id, problem1.id)
      LeetcodeSpaced.Study.add_problem_to_list(list.id, problem2.id)

      # Create reviews with different due times
      review_fixture(%{
        problem_id: problem1.id,
        user_id: user.id,
        list_id: list.id,
        # Due 2 hours ago (older)
        due: DateTime.add(DateTime.utc_now(), -2, :hour)
      })

      review_fixture(%{
        problem_id: problem2.id,
        user_id: user.id,
        list_id: list.id,
        # Due 1 hour ago (newer)
        due: DateTime.add(DateTime.utc_now(), -1, :hour)
      })

      due_problems = Reviews.get_due_problems_for_list(list.id, user.id)

      assert length(due_problems) == 2
      # Should be ordered by due date (oldest first)
      assert List.first(due_problems).id == problem1.id
      assert List.last(due_problems).id == problem2.id
    end
  end

  describe "mark_problem_solved/4" do
    import LeetcodeSpaced.StudyFixtures
    import LeetcodeSpaced.AccountsFixtures

    test "creates a new review for first time solving" do
      user = user_fixture()
      list = list_fixture(%{user_id: user.id})
      problem = problem_fixture()

      LeetcodeSpaced.Study.add_problem_to_list(list.id, problem.id)

      assert {:ok, _result} = Reviews.mark_problem_solved(problem.id, user.id, list.id, :good)

      # Check that a review was created
      from(r in Review,
        where: r.problem_id == ^problem.id and r.user_id == ^user.id and r.list_id == ^list.id
      )
      |> LeetcodeSpaced.Repo.one()
      |> case do
        nil ->
          flunk("Expected review to be created")

        review ->
          assert review.problem_id == problem.id
          assert review.user_id == user.id
          assert review.list_id == list.id
          assert review.review_count == 1
          assert review.fsrs_state in ["learning", "review"]
      end
    end

    test "updates existing review" do
      user = user_fixture()
      list = list_fixture(%{user_id: user.id})
      problem = problem_fixture()

      LeetcodeSpaced.Study.add_problem_to_list(list.id, problem.id)

      # Create initial review
      existing_review =
        review_fixture(%{
          problem_id: problem.id,
          user_id: user.id,
          list_id: list.id,
          review_count: 1
        })

      assert {:ok, _result} = Reviews.mark_problem_solved(problem.id, user.id, list.id, :easy)

      # Check that the review was updated
      updated_review = Reviews.get_review!(existing_review.id)
      assert updated_review.review_count == 2
      assert updated_review.reviewed_at != nil
    end

    test "handles all FSRS ratings" do
      user = user_fixture()
      list = list_fixture(%{user_id: user.id})

      for rating <- [:again, :hard, :good, :easy] do
        problem = problem_fixture()
        LeetcodeSpaced.Study.add_problem_to_list(list.id, problem.id)

        assert {:ok, _result} = Reviews.mark_problem_solved(problem.id, user.id, list.id, rating)

        from(r in Review,
          where: r.problem_id == ^problem.id and r.user_id == ^user.id and r.list_id == ^list.id
        )
        |> LeetcodeSpaced.Repo.one()
        |> case do
          nil ->
            flunk("Expected review to be created for rating #{rating}")

          review ->
            assert review.review_count == 1
        end
      end
    end

    test "returns error for invalid rating" do
      user = user_fixture()
      list = list_fixture(%{user_id: user.id})
      problem = problem_fixture()

      LeetcodeSpaced.Study.add_problem_to_list(list.id, problem.id)

      assert {:error, :invalid_rating} =
               Reviews.mark_problem_solved(problem.id, user.id, list.id, :invalid)
    end
  end
end
