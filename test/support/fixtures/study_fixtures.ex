defmodule LeetcodeSpaced.StudyFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LeetcodeSpaced.Study` context.
  """

  @doc """
  Generate a list.
  """
  def list_fixture(attrs \\ %{}) do
    {:ok, list} =
      attrs
      |> Enum.into(%{
        description: "some description",
        is_public: true,
        name: "some name"
      })
      |> LeetcodeSpaced.Study.create_list()

    list
  end

  @doc """
  Generate a unique problem leetcode_id.
  """
  def unique_problem_leetcode_id, do: System.unique_integer([:positive])

  @doc """
  Generate a problem.
  """
  def problem_fixture(attrs \\ %{}) do
    {:ok, problem} =
      attrs
      |> Enum.into(%{
        difficulty: "some difficulty",
        leetcode_id: unique_problem_leetcode_id(),
        leetcode_url: "some leetcode_url",
        title: "some title",
        topics: ["option1", "option2"]
      })
      |> LeetcodeSpaced.Study.create_problem()

    problem
  end
end
