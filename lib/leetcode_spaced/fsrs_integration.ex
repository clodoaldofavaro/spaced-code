defmodule LeetcodeSpaced.FsrsIntegration do
  @moduledoc """
  Integration module for the FSRS (Free Spaced Repetition System) algorithm.

  This module provides a bridge between our application's Review structs
  and the ExFsrs library, handling conversions and FSRS-specific logic.
  """

  alias LeetcodeSpaced.Reviews.Review

  @type fsrs_rating :: :again | :hard | :good | :easy

  @doc """
  Creates a new review record with initial FSRS values.

  ## Parameters
    - problem_id: The ID of the problem
    - user_id: The ID of the user

  ## Returns
    - A Review struct with initial FSRS state
  """
  def new_card(problem_id, user_id) do
    now = DateTime.utc_now()

    %Review{
      problem_id: problem_id,
      user_id: user_id,
      fsrs_state: "learning",
      fsrs_step: 0,
      stability: nil,
      difficulty: nil,
      review_count: 0,
      due: now,
      last_review: nil,
      confidence: nil,
      reviewed_at: nil,
      next_review: now
    }
  end

  @doc """
  Reviews a card using the FSRS algorithm.

  ## Parameters
    - review: A Review struct representing the current card state
    - rating: FSRS rating (:again, :hard, :good, or :easy)

  ## Returns
    - {:ok, updated_review} on success
    - {:error, reason} on failure
  """
  def review_card(%Review{} = review, rating) when rating in [:again, :hard, :good, :easy] do
    try do
      # Convert Review to ExFsrs card
      fsrs_card = to_fsrs_card(review)

      # Review the card using FSRS
      {updated_fsrs_card, _review_log} = ExFsrs.review_card(fsrs_card, rating)

      # Convert back to Review struct
      updated_review = from_fsrs_card(updated_fsrs_card, review.user_id)

      # Update review count and timestamps
      updated_review = %{updated_review |
        review_count: review.review_count + 1,
        reviewed_at: DateTime.utc_now(),
        next_review: updated_review.due
      }

      {:ok, updated_review}
    rescue
      error ->
        {:error, {:fsrs_error, error}}
    end
  end

  def review_card(_review, _rating) do
    {:error, :invalid_rating}
  end

  @doc """
  Converts a Review struct to an ExFsrs card.

  ## Parameters
    - review: A Review struct

  ## Returns
    - An ExFsrs card struct
  """
  def to_fsrs_card(%Review{} = review) do
    state = case review.fsrs_state do
      "learning" -> :learning
      "review" -> :review
      "relearning" -> :relearning
      _ -> :learning
    end

    ExFsrs.new(
      card_id: review.problem_id,
      state: state,
      step: review.fsrs_step,
      stability: review.stability,
      difficulty: review.difficulty,
      due: review.due || DateTime.utc_now(),
      last_review: review.last_review
    )
  end

  @doc """
  Converts an ExFsrs card back to Review attributes.

  ## Parameters
    - fsrs_card: An ExFsrs card struct
    - user_id: The user ID to associate with the review

  ## Returns
    - A Review struct with updated FSRS data
  """
  def from_fsrs_card(fsrs_card, user_id) do
    state = case fsrs_card.state do
      :learning -> "learning"
      :review -> "review"
      :relearning -> "relearning"
      _ -> "learning"
    end

    %Review{
      problem_id: fsrs_card.card_id,
      user_id: user_id,
      fsrs_state: state,
      fsrs_step: fsrs_card.step,
      stability: fsrs_card.stability,
      difficulty: fsrs_card.difficulty,
      due: fsrs_card.due,
      last_review: fsrs_card.last_review,
      review_count: 0,  # This will be updated by the caller
      confidence: nil,
      reviewed_at: nil,
      next_review: fsrs_card.due
    }
  end

  @doc """
  Checks if a review is due for study.

  ## Parameters
    - review: A Review struct
    - current_time: Current datetime (defaults to now)

  ## Returns
    - true if the review is due, false otherwise
  """
  def is_due?(%Review{} = review, current_time \\ DateTime.utc_now()) do
    case review.due do
      nil -> true  # If no due date, consider it due
      due_date -> DateTime.compare(due_date, current_time) != :gt
    end
  end

  @doc """
  Calculates the current retrievability (retention) of a card.

  ## Parameters
    - review: A Review struct
    - current_time: Current datetime (defaults to now)

  ## Returns
    - Float between 0 and 1 representing retrievability
  """
  def calculate_retention(%Review{} = review, current_time \\ DateTime.utc_now()) do
    case {review.stability, review.last_review} do
      {nil, _} -> 0.0
      {_, nil} -> 0.0
      {_stability, _last_review} ->
        fsrs_card = to_fsrs_card(review)
        ExFsrs.get_retrievability(fsrs_card, current_time)
    end
  end

  @doc """
  Gets the FSRS scheduler with optimized parameters.

  ## Returns
    - An ExFsrs.Scheduler struct
  """
  def get_scheduler() do
    ExFsrs.Scheduler.new(
      desired_retention: 0.9,
      enable_fuzzing: true,
      maximum_interval: 36500  # ~100 years max
    )
  end

  @doc """
  Validates an FSRS rating.

  ## Parameters
    - rating: The rating to validate

  ## Returns
    - true if valid, false otherwise
  """
  def valid_rating?(rating) when rating in [:again, :hard, :good, :easy], do: true
  def valid_rating?(_), do: false
end
