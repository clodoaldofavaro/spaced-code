defmodule LeetcodeSpaced.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :google_id, :string
      add :name, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:google_id])
    create unique_index(:users, [:email])
  end
end
