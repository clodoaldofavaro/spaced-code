defmodule LeetcodeSpaced.Study.Company do
  use Ecto.Schema
  import Ecto.Changeset

  schema "companies" do
    field :name, :string

    many_to_many :leetcode_problems, LeetcodeSpaced.Study.LeetcodeProblem,
      join_through: "leetcode_problem_companies",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(company, attrs) do
    company
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
