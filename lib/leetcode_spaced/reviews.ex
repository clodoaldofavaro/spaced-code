defmodule LeetcodeSpaced.Reviews do
  @moduledoc """
  The Reviews context.
  """

  import Ecto.Query, warn: false
  alias LeetcodeSpaced.Repo

  alias LeetcodeSpaced.Reviews.Review

  @doc """
  Returns the list of reviews.

  ## Examples

      iex> list_reviews()
      [%Review{}, ...]

  """
  def list_reviews do
    Repo.all(Review)
  end

  @doc """
  Gets a single review.

  Raises `Ecto.NoResultsError` if the Review does not exist.

  ## Examples

      iex> get_review!(123)
      %Review{}

      iex> get_review!(456)
      ** (Ecto.NoResultsError)

  """
  def get_review!(id), do: Repo.get!(Review, id)

  @doc """
  Creates a review.

  ## Examples

      iex> create_review(%{field: value})
      {:ok, %Review{}}

      iex> create_review(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_review(attrs) do
    %Review{}
    |> Review.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a review.

  ## Examples

      iex> update_review(review, %{field: new_value})
      {:ok, %Review{}}

      iex> update_review(review, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_review(%Review{} = review, attrs) do
    review
    |> Review.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a review.

  ## Examples

      iex> delete_review(review)
      {:ok, %Review{}}

      iex> delete_review(review)
      {:error, %Ecto.Changeset{}}

  """
  def delete_review(%Review{} = review) do
    Repo.delete(review)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking review changes.

  ## Examples

      iex> change_review(review)
      %Ecto.Changeset{data: %Review{}}

  """
  def change_review(%Review{} = review, attrs \\ %{}) do
    Review.changeset(review, attrs)
  end

  @doc """
  Gets problems due for review for a specific list and user using FSRS.
  """
  def get_due_problems_for_list(list_id, user_id) do
    today = DateTime.utc_now()
    
    from(p in LeetcodeSpaced.Study.Problem,
      join: lp in "lists_problems", on: lp.problem_id == p.id,
      left_join: r in Review, on: r.problem_id == p.id and r.user_id == ^user_id and r.list_id == ^list_id,
      where: lp.list_id == ^list_id and (is_nil(r.due) or r.due <= ^today),
      order_by: [asc: coalesce(r.due, p.inserted_at)],
      select: p
    )
    |> Repo.all()
  end

  @doc """
  Marks a problem as solved with an FSRS rating and schedules next review.
  
  ## Parameters
    - problem_id: ID of the problem
    - user_id: ID of the user
    - list_id: ID of the list
    - rating: FSRS rating (:again, :hard, :good, :easy)
  """
  def mark_problem_solved(problem_id, user_id, list_id, rating) do
    require Logger
    alias LeetcodeSpaced.FsrsIntegration
    
    Logger.info("Reviews.mark_problem_solved called with: #{problem_id}, #{user_id}, #{list_id}, #{rating}")
    
    existing_review = get_existing_review(problem_id, user_id, list_id)
    Logger.info("Existing review: #{inspect(existing_review)}")
    
    review = if existing_review do
      existing_review
    else
      FsrsIntegration.new_card(problem_id, user_id, list_id)
    end
    
    Logger.info("Review to process: #{inspect(review)}")
    
    case FsrsIntegration.review_card(review, rating) do
      {:ok, updated_review} ->
        Logger.info("FSRS review_card successful: #{inspect(updated_review)}")
        
        attrs = %{
          problem_id: updated_review.problem_id,
          user_id: updated_review.user_id,
          list_id: updated_review.list_id,
          fsrs_state: updated_review.fsrs_state,
          fsrs_step: updated_review.fsrs_step,
          stability: updated_review.stability,
          difficulty: updated_review.difficulty,
          due: updated_review.due,
          last_review: updated_review.last_review,
          review_count: updated_review.review_count,
          reviewed_at: updated_review.reviewed_at,
          next_review: updated_review.next_review
        }
        
        Logger.info("Attributes to save: #{inspect(attrs)}")
        
        result = if existing_review do
          Logger.info("Updating existing review")
          update_review(existing_review, attrs)
        else
          Logger.info("Creating new review")
          create_review(attrs)
        end
        
        Logger.info("Database operation result: #{inspect(result)}")
        result
        
      {:error, reason} ->
        Logger.error("FSRS review_card failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_existing_review(problem_id, user_id, list_id) do
    from(r in Review,
      where: r.problem_id == ^problem_id and r.user_id == ^user_id and r.list_id == ^list_id
    )
    |> Repo.one()
  end
end
