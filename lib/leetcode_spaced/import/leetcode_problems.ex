defmodule LeetcodeSpaced.Import.LeetcodeProblems do
  @moduledoc """
  Module for importing LeetCode problems from CSV files.

  CSV files should be stored in `priv/data/` and follow the format:
  id;name;url;difficulty;category;is_premium
  """

  alias LeetcodeSpaced.Repo
  alias LeetcodeSpaced.Study.{LeetcodeProblem, Category}

  @doc """
  Import all CSV files from the priv/data directory.
  """
  def import_all do
    data_dir = Path.join([:code.priv_dir(:leetcode_spaced), "data"])

    case File.ls(data_dir) do
      {:ok, files} ->
        csv_files = Enum.filter(files, &String.ends_with?(&1, ".csv"))

        if Enum.empty?(csv_files) do
          IO.puts("No CSV files found in #{data_dir}")
          {:error, :no_csv_files}
        else
          IO.puts("Found #{length(csv_files)} CSV files to import")
          import_files(csv_files, data_dir)
        end

      {:error, reason} ->
        IO.puts("Error reading data directory: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Import a specific CSV file.
  """
  def import_file(filename) do
    data_dir = Path.join([:code.priv_dir(:leetcode_spaced), "data"])
    file_path = Path.join(data_dir, filename)

    if File.exists?(file_path) do
      import_single_file(file_path, filename)
    else
      IO.puts("File not found: #{file_path}")
      {:error, :file_not_found}
    end
  end

  defp import_files(files, data_dir) do
    results =
      Enum.map(files, fn file ->
        file_path = Path.join(data_dir, file)
        import_single_file(file_path, file)
      end)

    summarize_results(results)
  end

  defp import_single_file(file_path, filename) do
    IO.puts("Importing #{filename}...")

    case File.read(file_path) do
      {:ok, content} ->
        process_csv_content(content, filename)

      {:error, reason} ->
        IO.puts("Error reading file #{filename}: #{reason}")
        {:error, reason}
    end
  end

  defp process_csv_content(content, filename) do
    lines = String.split(content, "\n", trim: true)

    case lines do
      [header | data_lines] ->
        if valid_header?(header) do
          process_data_lines(data_lines, filename)
        else
          IO.puts("Invalid header format in #{filename}")
          {:error, :invalid_header}
        end

      [] ->
        IO.puts("Empty file: #{filename}")
        {:error, :empty_file}
    end
  end

  defp valid_header?(header) do
    expected_columns = ["id", "name", "url", "difficulty", "category", "is_premium"]
    actual_columns = String.split(header, ";")
    actual_columns == expected_columns
  end

  defp process_data_lines(lines, filename) do
    Repo.transaction(fn ->
      results =
        Enum.map(lines, fn line ->
          case parse_csv_line(line) do
            {:ok, data} ->
              process_problem(data, filename)

            {:error, reason} ->
              IO.puts("Error parsing line in #{filename}: #{reason}")
              {:error, reason}
          end
        end)

      # Return summary
      successful = Enum.count(results, &match?({:ok, _}, &1))
      errors = Enum.count(results, &match?({:error, _}, &1))

      %{created: successful, errors: errors}
    end)
  end

  defp parse_csv_line(line) do
    case String.split(line, ";") do
      [id_str, name, url, difficulty, category, is_premium_str] ->
        with {:ok, id} <- parse_integer(id_str),
             {:ok, is_premium} <- parse_boolean(is_premium_str) do
          {:ok,
           %{
             leetcode_id: id,
             name: name,
             url: url,
             difficulty: difficulty,
             category: category,
             is_premium: is_premium
           }}
        end

      _ ->
        {:error, "Invalid number of columns"}
    end
  end

  defp parse_integer(str) do
    case Integer.parse(str) do
      {int, ""} -> {:ok, int}
      _ -> {:error, "Invalid integer: #{str}"}
    end
  end

  defp parse_boolean("true"), do: {:ok, true}
  defp parse_boolean("false"), do: {:ok, false}
  defp parse_boolean(str), do: {:error, "Invalid boolean: #{str}"}

  defp process_problem(data, _filename) do
    # Check if problem already exists
    case Repo.get_by(LeetcodeProblem, leetcode_id: data.leetcode_id) do
      nil ->
        # Create new problem
        create_problem_with_category(data)

      existing_problem ->
        # Problem exists, just add category if needed
        add_category_to_problem(existing_problem, data.category)
    end
  end

  defp create_problem_with_category(data) do
    # Create or get category
    category = get_or_create_category(data.category)

    # Create problem
    problem_attrs = %{
      leetcode_id: data.leetcode_id,
      name: data.name,
      url: data.url,
      difficulty: data.difficulty,
      is_premium: data.is_premium
    }

    case %LeetcodeProblem{}
         |> LeetcodeProblem.changeset(problem_attrs)
         |> Repo.insert() do
      {:ok, problem} ->
        # Associate with category
        associate_problem_with_category(problem, category)
        {:ok, :created}

      {:error, changeset} ->
        {:error, "Failed to create problem: #{inspect(changeset.errors)}"}
    end
  end

  defp add_category_to_problem(problem, category_name) do
    category = get_or_create_category(category_name)
    associate_problem_with_category(problem, category)
    {:ok, :category_added}
  end

  defp get_or_create_category(name) do
    case Repo.get_by(Category, name: name) do
      nil ->
        {:ok, category} =
          %Category{}
          |> Category.changeset(%{name: name})
          |> Repo.insert()

        category

      category ->
        category
    end
  end

  defp associate_problem_with_category(problem, category) do
    # Check if association already exists
    query = """
    SELECT 1 FROM leetcode_problem_categories
    WHERE leetcode_problem_id = $1 AND category_id = $2
    """

    case Repo.query(query, [problem.id, category.id]) do
      {:ok, %{num_rows: 0}} ->
        # Association doesn't exist, create it
        Repo.insert_all("leetcode_problem_categories", [
          [
            leetcode_problem_id: problem.id,
            category_id: category.id,
            inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
            updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
          ]
        ])

      _ ->
        # Association already exists, do nothing
        :ok
    end
  end

  defp summarize_results(results) do
    total_created =
      Enum.sum(
        Enum.map(results, fn
          %{created: created} -> created
          {:ok, %{created: created}} -> created
          _ -> 0
        end)
      )

    total_errors =
      Enum.sum(
        Enum.map(results, fn
          %{errors: errors} -> errors
          {:ok, %{errors: errors}} -> errors
          _ -> 0
        end)
      )

    IO.puts("\n=== Import Summary ===")
    IO.puts("Total problems created: #{total_created}")
    IO.puts("Total errors: #{total_errors}")

    {:ok, %{created: total_created, errors: total_errors}}
  end
end
