defmodule HtmzPhxWeb.CartController do
  use HtmzPhxWeb, :controller

  def add(conn, %{"item_id" => item_id_str}) do
    user_id = conn.assigns[:current_user_id]

    case Integer.parse(item_id_str) do
      {item_id, ""} ->
        case HtmzPhx.CartManager.add_to_cart(user_id, item_id) do
          :ok ->
            conn
            |> put_root_layout(false)
            |> put_layout(false)
            |> put_resp_header("hx-trigger", "updateCartCount, cartUpdate")
            |> send_resp(200, "OK")

          {:error, reason} ->
            conn
            |> put_root_layout(false)
            |> put_layout(false)
            |> put_status(500)
            |> text("Error: #{reason}")
        end

      _ ->
        conn
        |> put_root_layout(false)
        |> put_layout(false)
        |> put_status(400)
        |> text("Invalid item ID")
    end
  end

  def remove(conn, %{"item_id" => item_id_str}) do
    user_id = conn.assigns[:current_user_id]

    case Integer.parse(item_id_str) do
      {item_id, ""} ->
        case HtmzPhx.CartManager.remove_from_cart(user_id, item_id) do
          :ok ->
            conn
            |> put_resp_header("hx-trigger", "updateCartCount, cartUpdate")
            |> put_resp_header("hx-refresh", "true")
            |> send_resp(200, "OK")

          {:error, reason} ->
            conn
            |> put_status(500)
            |> text("Error: #{reason}")
        end

      _ ->
        conn
        |> put_status(400)
        |> text("Invalid item ID")
    end
  end

  def increase_quantity(conn, %{"item_id" => item_id_str}) do
    user_id = conn.assigns[:current_user_id]

    case Integer.parse(item_id_str) do
      {item_id, ""} ->
        case HtmzPhx.CartManager.increase_quantity(user_id, item_id) do
          {:ok, item} ->
            item_total = :erlang.float_to_binary(item.price * item.quantity, decimals: 2)

            html_content = """
            <div class="flex items-center space-x-4">
              <div class="flex items-center space-x-2">
                <button class="btn btn-sm btn-circle btn-outline"
                        hx-post="/api/cart/decrease-quantity/#{item_id}"
                        hx-target="#item-row-#{item_id}"
                        hx-swap="outerHTML">
                  -
                </button>

                <span id="quantity-#{item_id}"
                      class="w-8 text-center font-semibold">
                  #{item.quantity}
                </span>

                <button class="btn btn-sm btn-circle btn-outline"
                        hx-post="/api/cart/increase-quantity/#{item_id}"
                        hx-target="#item-row-#{item_id}"
                        hx-swap="outerHTML">
                  +
                </button>
              </div>

              <span class="font-bold text-primary min-w-[4rem]">
                $ #{item_total}
              </span>

              <button class="btn btn-sm btn-error btn-outline"
                      hx-delete="/api/cart/remove/#{item_id}"
                      hx-swap="none">
                Remove
              </button>
            </div>
            """

            conn
            |> put_resp_header("hx-trigger", "updateCartCount, cartUpdate")
            |> put_resp_content_type("text/html")
            |> text(html_content)

          {:error, reason} ->
            conn
            |> put_status(500)
            |> text("Error: #{reason}")
        end

      _ ->
        conn
        |> put_status(400)
        |> text("Invalid item ID")
    end
  end

  def decrease_quantity(conn, %{"item_id" => item_id_str}) do
    user_id = conn.assigns[:current_user_id]

    case Integer.parse(item_id_str) do
      {item_id, ""} ->
        case HtmzPhx.CartManager.decrease_quantity(user_id, item_id) do
          {:ok, :removed} ->
            # Item was removed, return empty content and let the page refresh handle it
            conn
            |> put_resp_header("hx-trigger", "updateCartCount, cartUpdate")
            |> put_resp_header("hx-refresh", "true")
            |> put_resp_content_type("text/html")
            |> text("")

          {:ok, item} ->
            item_total = :erlang.float_to_binary(item.price * item.quantity, decimals: 2)

            html_content = """
              <div class="flex items-center space-x-4">
                <div class="flex items-center space-x-2">
                  <button class="btn btn-sm btn-circle btn-outline"
                          hx-post="/api/cart/decrease-quantity/#{item_id}"
                          hx-target="#item-row-#{item_id}"
                          hx-swap="outerHTML">
                    -
                  </button>

                  <span id="quantity-#{item_id}"
                        class="w-8 text-center font-semibold">
                    #{item.quantity}
                  </span>

                  <button class="btn btn-sm btn-circle btn-outline"
                          hx-post="/api/cart/increase-quantity/#{item_id}"
                          hx-target="#item-row-#{item_id}"
                          hx-swap="outerHTML">
                    +
                  </button>
                </div>

                <span class="font-bold text-primary min-w-[4rem]">
                  $#{item_total}
                </span>

                <button class="btn btn-sm btn-error btn-outline"
                        hx-delete="/api/cart/remove/#{item_id}"
                        hx-swap="none">
                  Remove
                </button>
              </div>
              """

            conn
            |> put_resp_header("hx-trigger", "updateCartCount, cartUpdate")
            |> put_resp_content_type("text/html")
            |> text(html_content)

          {:error, reason} ->
            conn
            |> put_status(500)
            |> text("Error: #{reason}")
        end

      _ ->
        conn
        |> put_status(400)
        |> text("Invalid item ID")
    end
  end

  def get_items(conn, _params) do
    items = HtmzPhx.GroceryItems.get_all_items()
    json(conn, items)
  end

  def cleanup_carts(conn, _params) do
    # Clean up all carts (for testing purposes)
    # In production, you might want to implement more sophisticated cleanup
    :ets.delete_all_objects(:cart_storage)

    conn
    |> put_resp_content_type("text/plain")
    |> text("Carts cleaned up")
  end
end
