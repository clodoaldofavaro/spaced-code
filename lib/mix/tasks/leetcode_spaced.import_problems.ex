defmodule Mix.Tasks.LeetcodeSpaced.ImportProblems do
  @moduledoc """
  Mix task to import LeetCode problems from CSV files.

  ## Usage

      mix leetcode_spaced.import_problems
      mix leetcode_spaced.import_problems --file=backtracking.csv
  """

  use Mix.Task
  alias LeetcodeSpaced.Import.LeetcodeProblems

  @shortdoc "Import LeetCode problems from CSV files"

  @impl Mix.Task
  def run(args) do
    # Start the application to ensure the database is available
    Mix.Task.run("app.start")

    case parse_args(args) do
      {:ok, %{file: nil}} ->
        IO.puts("Importing all CSV files...")
        case LeetcodeProblems.import_all() do
          {:ok, summary} ->
            IO.puts("Import completed successfully!")
            IO.puts("Problems created: #{summary.created}")
            IO.puts("Errors: #{summary.errors}")

          {:error, reason} ->
            IO.puts("Import failed: #{inspect(reason)}")
            System.halt(1)
        end

      {:ok, %{file: filename}} ->
        IO.puts("Importing file: #{filename}")
        case LeetcodeProblems.import_file(filename) do
          {:ok, summary} ->
            IO.puts("Import completed successfully!")
            IO.puts("Problems created: #{summary.created}")
            IO.puts("Errors: #{summary.errors}")

          {:error, reason} ->
            IO.puts("Import failed: #{inspect(reason)}")
            System.halt(1)
        end

      {:error, message} ->
        IO.puts("Error: #{message}")
        IO.puts("\nUsage:")
        IO.puts("  mix leetcode_spaced.import_problems")
        IO.puts("  mix leetcode_spaced.import_problems --file=filename.csv")
        System.halt(1)
    end
  end

  defp parse_args(args) do
    {opts, _} = OptionParser.parse!(args, strict: [file: :string])

    case opts do
      [] -> {:ok, %{file: nil}}
      [file: filename] -> {:ok, %{file: filename}}
      _ -> {:error, "Invalid arguments"}
    end
  rescue
    OptionParser.ParseError ->
      {:error, "Invalid arguments"}
  end
end
