defmodule HtmzPhx.CartManager do
  @moduledoc """
  ETS-based shopping cart manager with GenServer for serialized access
  Table structure: {user_id, [{item_id, quantity}]}
  """

  use GenServer
  @table_name :cart_storage

  # Client API
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_to_cart(user_id, item_id) do
    GenServer.call(__MODULE__, {:add_to_cart, user_id, item_id})
  end

  def remove_from_cart(user_id, item_id) do
    GenServer.call(__MODULE__, {:remove_from_cart, user_id, item_id})
  end

  def increase_quantity(user_id, item_id) do
    GenServer.call(__MODULE__, {:increase_quantity, user_id, item_id})
  end

  def decrease_quantity(user_id, item_id) do
    GenServer.call(__MODULE__, {:decrease_quantity, user_id, item_id})
  end

  def get_cart_count(user_id) do
    GenServer.call(__MODULE__, {:get_cart_count, user_id})
  end

  def get_cart_total(user_id) do
    GenServer.call(__MODULE__, {:get_cart_total, user_id})
  end

  def get_cart(user_id) do
    GenServer.call(__MODULE__, {:get_cart, user_id})
  end

  def clear_cart(user_id) do
    GenServer.call(__MODULE__, {:clear_cart, user_id})
  end

  # Server callbacks
  def init(_) do
    @table_name = :ets.new(@table_name, [:set, :public, :named_table])
    {:ok, %{}}
  end

  def handle_call({:add_to_cart, user_id, item_id}, _from, state) do
    cart = get_user_cart(user_id)

    updated_cart =
      case List.keyfind(cart, item_id, 0) do
        {^item_id, quantity} ->
          List.keyreplace(cart, item_id, 0, {item_id, quantity + 1})

        nil ->
          [{item_id, 1} | cart]
      end

    :ets.insert(@table_name, {user_id, updated_cart})
    {:reply, :ok, state}
  end

  def handle_call({:remove_from_cart, user_id, item_id}, _from, state) do
    cart = get_user_cart(user_id)
    updated_cart = List.keydelete(cart, item_id, 0)
    :ets.insert(@table_name, {user_id, updated_cart})
    {:reply, :ok, state}
  end

  def handle_call({:increase_quantity, user_id, item_id}, _from, state) do
    cart = get_user_cart(user_id)

    case List.keyfind(cart, item_id, 0) do
      {^item_id, quantity} ->
        new_quantity = quantity + 1
        updated_cart = List.keyreplace(cart, item_id, 0, {item_id, new_quantity})
        :ets.insert(@table_name, {user_id, updated_cart})

        # Return the updated item with price information
        case HtmzPhx.GroceryItems.get_grocery_item(item_id) do
          {:ok, item} ->
            updated_item = %{
              id: item_id,
              name: item.name,
              quantity: new_quantity,
              price: item.price
            }

            {:reply, {:ok, updated_item}, state}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end

      nil ->
        # Item not in cart, do nothing
        {:reply, {:error, :item_not_found}, state}
    end
  end

  def handle_call({:decrease_quantity, user_id, item_id}, _from, state) do
    cart = get_user_cart(user_id)

    case List.keyfind(cart, item_id, 0) do
      {^item_id, 1} ->
        # Remove if quantity becomes 0
        updated_cart = List.keydelete(cart, item_id, 0)
        :ets.insert(@table_name, {user_id, updated_cart})
        {:reply, {:ok, :removed}, state}

      {^item_id, quantity} ->
        new_quantity = quantity - 1
        updated_cart = List.keyreplace(cart, item_id, 0, {item_id, new_quantity})
        :ets.insert(@table_name, {user_id, updated_cart})

        # Return the updated item with price information
        case HtmzPhx.GroceryItems.get_grocery_item(item_id) do
          {:ok, item} ->
            updated_item = %{
              id: item_id,
              name: item.name,
              quantity: new_quantity,
              price: item.price
            }

            {:reply, {:ok, updated_item}, state}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end

      nil ->
        # Item not in cart, do nothing
        {:reply, {:error, :item_not_found}, state}
    end
  end

  def handle_call({:get_cart_count, user_id}, _from, state) do
    cart = get_user_cart(user_id)

    total_count =
      Enum.reduce(cart, 0, fn {_item_id, quantity}, acc ->
        acc + quantity
      end)

    {:reply, total_count, state}
  end

  def handle_call({:get_cart_total, user_id}, _from, state) do
    cart = get_user_cart(user_id)

    total =
      Enum.reduce(cart, 0.0, fn {item_id, quantity}, acc ->
        case HtmzPhx.GroceryItems.get_grocery_item(item_id) do
          {:ok, item} -> acc + item.price * quantity
          {:error, _} -> acc
        end
      end)

    {:reply, total, state}
  end

  def handle_call({:get_cart, user_id}, _from, state) do
    cart = get_user_cart(user_id)

    cart_items =
      Enum.map(cart, fn {item_id, quantity} ->
        case HtmzPhx.GroceryItems.get_grocery_item(item_id) do
          {:ok, item} ->
            %{id: item_id, name: item.name, quantity: quantity, price: item.price}

          {:error, _} ->
            nil
        end
      end)
      |> Enum.filter(&(&1 != nil))

    {:reply, cart_items, state}
  end

  def handle_call({:clear_cart, user_id}, _from, state) do
    :ets.delete(@table_name, user_id)
    {:reply, :ok, state}
  end

  # Private helpers
  defp get_user_cart(user_id) do
    case :ets.lookup(@table_name, user_id) do
      [{^user_id, cart}] -> cart
      [] -> []
    end
  end
end
