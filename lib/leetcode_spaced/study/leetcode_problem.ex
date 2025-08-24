defmodule LeetcodeSpaced.Study.LeetcodeProblem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "leetcode_problems" do
    field :leetcode_id, :integer
    field :name, :string
    field :url, :string
    field :difficulty, :string
    field :is_premium, :boolean, default: false

    many_to_many :categories, LeetcodeSpaced.Study.Category,
      join_through: "leetcode_problem_categories",
      on_replace: :delete

    many_to_many :companies, LeetcodeSpaced.Study.Company,
      join_through: "leetcode_problem_companies",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(leetcode_problem, attrs) do
    leetcode_problem
    |> cast(attrs, [:leetcode_id, :name, :url, :difficulty, :is_premium])
    |> validate_required([:leetcode_id, :name, :url, :difficulty])
    |> validate_inclusion(:difficulty, ["Easy", "Medium", "Hard"])
    |> unique_constraint(:leetcode_id)
  end
end
