defmodule LeetcodeSpaced.StudyTest do
  use LeetcodeSpaced.DataCase

  alias LeetcodeSpaced.Study

  describe "lists" do
    alias LeetcodeSpaced.Study.List

    import LeetcodeSpaced.StudyFixtures

    @invalid_attrs %{name: nil, description: nil, is_public: nil}

    test "list_lists/0 returns all lists" do
      list = list_fixture()
      assert Study.list_lists() == [list]
    end

    test "get_list!/1 returns the list with given id" do
      list = list_fixture()
      assert Study.get_list!(list.id) == list
    end

    test "create_list/1 with valid data creates a list" do
      valid_attrs = %{name: "some name", description: "some description", is_public: true}

      assert {:ok, %List{} = list} = Study.create_list(valid_attrs)
      assert list.name == "some name"
      assert list.description == "some description"
      assert list.is_public == true
    end

    test "create_list/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Study.create_list(@invalid_attrs)
    end

    test "update_list/2 with valid data updates the list" do
      list = list_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        is_public: false
      }

      assert {:ok, %List{} = list} = Study.update_list(list, update_attrs)
      assert list.name == "some updated name"
      assert list.description == "some updated description"
      assert list.is_public == false
    end

    test "update_list/2 with invalid data returns error changeset" do
      list = list_fixture()
      assert {:error, %Ecto.Changeset{}} = Study.update_list(list, @invalid_attrs)
      assert list == Study.get_list!(list.id)
    end

    test "delete_list/1 deletes the list" do
      list = list_fixture()
      assert {:ok, %List{}} = Study.delete_list(list)
      assert_raise Ecto.NoResultsError, fn -> Study.get_list!(list.id) end
    end

    test "change_list/1 returns a list changeset" do
      list = list_fixture()
      assert %Ecto.Changeset{} = Study.change_list(list)
    end
  end

  describe "problems" do
    alias LeetcodeSpaced.Study.Problem

    import LeetcodeSpaced.StudyFixtures

    @invalid_attrs %{
      title: nil,
      leetcode_url: nil,
      leetcode_id: nil,
      difficulty: nil,
      topics: nil
    }

    test "list_problems/0 returns all problems" do
      problem = problem_fixture()
      assert Study.list_problems() == [problem]
    end

    test "get_problem!/1 returns the problem with given id" do
      problem = problem_fixture()
      assert Study.get_problem!(problem.id) == problem
    end

    test "create_problem/1 with valid data creates a problem" do
      valid_attrs = %{
        title: "some title",
        leetcode_url: "some leetcode_url",
        leetcode_id: 42,
        difficulty: "some difficulty",
        topics: ["option1", "option2"]
      }

      assert {:ok, %Problem{} = problem} = Study.create_problem(valid_attrs)
      assert problem.title == "some title"
      assert problem.leetcode_url == "some leetcode_url"
      assert problem.leetcode_id == 42
      assert problem.difficulty == "some difficulty"
      assert problem.topics == ["option1", "option2"]
    end

    test "create_problem/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Study.create_problem(@invalid_attrs)
    end

    test "update_problem/2 with valid data updates the problem" do
      problem = problem_fixture()

      update_attrs = %{
        title: "some updated title",
        leetcode_url: "some updated leetcode_url",
        leetcode_id: 43,
        difficulty: "some updated difficulty",
        topics: ["option1"]
      }

      assert {:ok, %Problem{} = problem} = Study.update_problem(problem, update_attrs)
      assert problem.title == "some updated title"
      assert problem.leetcode_url == "some updated leetcode_url"
      assert problem.leetcode_id == 43
      assert problem.difficulty == "some updated difficulty"
      assert problem.topics == ["option1"]
    end

    test "update_problem/2 with invalid data returns error changeset" do
      problem = problem_fixture()
      assert {:error, %Ecto.Changeset{}} = Study.update_problem(problem, @invalid_attrs)
      assert problem == Study.get_problem!(problem.id)
    end

    test "delete_problem/1 deletes the problem" do
      problem = problem_fixture()
      assert {:ok, %Problem{}} = Study.delete_problem(problem)
      assert_raise Ecto.NoResultsError, fn -> Study.get_problem!(problem.id) end
    end

    test "change_problem/1 returns a problem changeset" do
      problem = problem_fixture()
      assert %Ecto.Changeset{} = Study.change_problem(problem)
    end
  end
end
