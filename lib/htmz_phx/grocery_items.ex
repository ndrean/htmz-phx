defmodule HtmzPhx.GroceryItems do
  use Ecto.Schema
  alias HtmzPhx.Repo

  @derive {Jason.Encoder, only: [:id, :name, :price, :svg_data]}
  schema "grocery_items" do
    field :name, :string
    field :price, :float
    field :svg_data, :string

    timestamps(type: :utc_datetime)
  end

  def get_all_items do
    Repo.all(__MODULE__)
  end

  def get_grocery_item(id) do
    case Repo.get(__MODULE__, id) do
      nil -> {:error, :not_found}
      item -> {:ok, item}
    end
  end

  defp read_svg_file(filename) do
    svg_path = Path.join([Application.app_dir(:htmz_phx, "priv"), "static", "images", filename])
    case File.read(svg_path) do
      {:ok, content} -> content
      {:error, _} ->
        # Fallback to a simple placeholder if file not found
        "<svg width='24' height='24' viewBox='0 0 24 24' fill='none' xmlns='http://www.w3.org/2000/svg'><circle cx='12' cy='12' r='10' fill='gray'/></svg>"
    end
  end

  def create_items do
    # Insert real grocery items matching the Zig version by reading actual SVG files
    items = [
      %{name: "Apple", price: 0.50, svg_file: "apple-svgrepo-com.svg"},
      %{name: "Bananas", price: 0.30, svg_file: "banana-svgrepo-com.svg"},
      %{name: "Bread", price: 2.00, svg_file: "bread-svgrepo-com.svg"},
      %{name: "Cheese", price: 3.00, svg_file: "cheese-svgrepo-com.svg"},
      %{name: "Chicken", price: 5.00, svg_file: "chicken-svgrepo-com.svg"},
      %{name: "Fish", price: 7.00, svg_file: "fish-svgrepo-com.svg"},
      %{name: "Grapes", price: 2.50, svg_file: "grapes-svgrepo-com.svg"},
      %{name: "Carrot", price: 0.20, svg_file: "carrot-svgrepo-com.svg"},
      %{name: "Doughnut", price: 1.00, svg_file: "doughnut-svgrepo-com.svg"},
      %{name: "Eggs (dozen)", price: 2.50, svg_file: "eggs-svgrepo-com.svg"}
    ]

    Enum.each(items, fn item_attrs ->
      svg_data = read_svg_file(item_attrs.svg_file)
      item_attrs = Map.put(item_attrs, :svg_data, svg_data) |> Map.delete(:svg_file)

      %__MODULE__{}
      |> Ecto.Changeset.change(item_attrs)
      |> Repo.insert!(on_conflict: :nothing)
    end)
  end
end