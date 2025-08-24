defmodule LeetcodeSpaced.Study.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string

    many_to_many :leetcode_problems, LeetcodeSpaced.Study.LeetcodeProblem,
      join_through: "leetcode_problem_categories",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
