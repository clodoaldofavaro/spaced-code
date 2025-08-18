defmodule LeetcodeSpaced.Study do
  @moduledoc """
  The Study context.
  """

  import Ecto.Query, warn: false
  alias LeetcodeSpaced.Repo

  alias LeetcodeSpaced.Study.List

  @doc """
  Returns the list of lists.

  ## Examples

      iex> list_lists()
      [%List{}, ...]

  """
  def list_lists do
    Repo.all(List)
  end

  @doc """
  Returns the list of lists for a specific user.

  ## Examples

      iex> list_lists_for_user(123)
      [%List{}, ...]

  """
  def list_lists_for_user(user_id) do
    from(l in List, where: l.user_id == ^user_id, order_by: [desc: l.inserted_at])
    |> Repo.all()
  end

  @doc """
  Gets a single list.

  Raises `Ecto.NoResultsError` if the List does not exist.

  ## Examples

      iex> get_list!(123)
      %List{}

      iex> get_list!(456)
      ** (Ecto.NoResultsError)

  """
  def get_list!(id), do: Repo.get!(List, id)

  @doc """
  Creates a list.

  ## Examples

      iex> create_list(%{field: value})
      {:ok, %List{}}

      iex> create_list(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_list(attrs) do
    %List{}
    |> List.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a list.

  ## Examples

      iex> update_list(list, %{field: new_value})
      {:ok, %List{}}

      iex> update_list(list, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_list(%List{} = list, attrs) do
    list
    |> List.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a list.

  ## Examples

      iex> delete_list(list)
      {:ok, %List{}}

      iex> delete_list(list)
      {:error, %Ecto.Changeset{}}

  """
  def delete_list(%List{} = list) do
    Repo.delete(list)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking list changes.

  ## Examples

      iex> change_list(list)
      %Ecto.Changeset{data: %List{}}

  """
  def change_list(%List{} = list, attrs \\ %{}) do
    List.changeset(list, attrs)
  end

  alias LeetcodeSpaced.Study.Problem

  @doc """
  Returns the list of problems.

  ## Examples

      iex> list_problems()
      [%Problem{}, ...]

  """
  def list_problems do
    Repo.all(Problem)
  end

  @doc """
  Gets a single problem.

  Raises `Ecto.NoResultsError` if the Problem does not exist.

  ## Examples

      iex> get_problem!(123)
      %Problem{}

      iex> get_problem!(456)
      ** (Ecto.NoResultsError)

  """
  def get_problem!(id), do: Repo.get!(Problem, id)

  @doc """
  Creates a problem.

  ## Examples

      iex> create_problem(%{field: value})
      {:ok, %Problem{}}

      iex> create_problem(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_problem(attrs) do
    %Problem{}
    |> Problem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a problem.

  ## Examples

      iex> update_problem(problem, %{field: new_value})
      {:ok, %Problem{}}

      iex> update_problem(problem, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_problem(%Problem{} = problem, attrs) do
    problem
    |> Problem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a problem.

  ## Examples

      iex> delete_problem(problem)
      {:ok, %Problem{}}

      iex> delete_problem(problem)
      {:error, %Ecto.Changeset{}}

  """
  def delete_problem(%Problem{} = problem) do
    Repo.delete(problem)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking problem changes.

  ## Examples

      iex> change_problem(problem)
      %Ecto.Changeset{data: %Problem{}}

  """
  def change_problem(%Problem{} = problem, attrs \\ %{}) do
    Problem.changeset(problem, attrs)
  end

  @doc """
  Gets problems for a specific list.
  """
  def get_problems_for_list(list_id) do
    from(p in Problem,
      join: lp in "lists_problems", on: lp.problem_id == p.id,
      where: lp.list_id == ^list_id,
      order_by: [asc: p.old_leetcode_id]
    )
    |> Repo.all()
  end

  @doc """
  Adds a problem to a list.
  """
  def add_problem_to_list(list_id, problem_id) do
    attrs = %{
      list_id: list_id, 
      problem_id: problem_id, 
      inserted_at: DateTime.utc_now(), 
      updated_at: DateTime.utc_now()
    }
    
    case Repo.insert_all("lists_problems", [attrs]) do
      {1, _} -> {:ok, :added}
      _ -> {:error, :failed}
    end
  end

  @doc """
  Removes a problem from a list.
  """
  def remove_problem_from_list(list_id, problem_id) do
    case from(lp in "lists_problems",
      where: lp.list_id == ^list_id and lp.problem_id == ^problem_id
    )
    |> Repo.delete_all() do
      {1, _} -> {:ok, :removed}
      {0, _} -> {:error, :not_found}
      _ -> {:error, :failed}
    end
  end
end
