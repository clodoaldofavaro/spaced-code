defmodule LeetcodeSpaced.Study.List do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lists" do
    field :name, :string
    field :description, :string
    field :is_public, :boolean, default: false
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(list, attrs) do
    list
    |> cast(attrs, [:name, :description, :is_public, :user_id])
    |> validate_required([:name, :description, :is_public, :user_id])
  end
end
