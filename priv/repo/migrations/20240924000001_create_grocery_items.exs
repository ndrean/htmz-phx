defmodule HtmzPhx.Repo.Migrations.CreateGroceryItems do
  use Ecto.Migration

  def change do
    create table(:grocery_items) do
      add :name, :string, null: false
      add :price, :float, null: false
      add :svg_data, :text

      timestamps(type: :utc_datetime)
    end

    create index(:grocery_items, [:name])
  end
end