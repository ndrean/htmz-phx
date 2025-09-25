defmodule HtmzPhxWeb.PageController do
  # alias JOSE.JWT
  use HtmzPhxWeb, :controller

  def index(conn, _params) do
    user_id = conn.assigns[:current_user_id]
    items = HtmzPhx.GroceryItems.get_all_items()
    cart_count = HtmzPhx.CartManager.get_cart_count(user_id)

    if get_req_header(conn, "hx-request") != [] do
      # HTMX request - return partial content
      conn
      |> put_root_layout(false)
      |> put_layout(false)
      |> render(:index,
        items: items,
        cart_count: cart_count,
        user_token: conn.assigns[:jwt_token]
      )
    else
      # Regular request - return full layout
      render(conn, :index,
        items: items,
        cart_count: cart_count,
        user_token: conn.assigns[:jwt_token]
      )
    end
  end

  def cart(conn, _params) do
    user_id = conn.assigns[:current_user_id]
    cart_items = HtmzPhx.CartManager.get_cart(user_id)
    cart_total = HtmzPhx.CartManager.get_cart_total(user_id)
    cart_count = HtmzPhx.CartManager.get_cart_count(user_id)

    if get_req_header(conn, "hx-request") != [] do
      # HTMX request - return partial content
      conn
      |> put_root_layout(false)
      |> put_layout(false)
      |> render(:cart,
        cart_items: cart_items,
        cart_total: cart_total,
        cart_count: cart_count,
        user_token: conn.assigns[:jwt_token]
      )
    else
      # Regular request - return full layout
      render(conn, :cart,
        cart_items: cart_items,
        cart_total: cart_total,
        cart_count: cart_count,
        user_token: conn.assigns[:jwt_token]
      )
    end
  end

  def item_details(conn, %{"id" => id}) do
    case Integer.parse(id) do
      {item_id, ""} ->
        case HtmzPhx.GroceryItems.get_grocery_item(item_id) do
          {:ok, item} ->
            render(conn, :item_details, item: item)

          {:error, :not_found} ->
            conn
            |> put_status(:not_found)
            |> render(:not_found)
        end

      _ ->
        conn
        |> put_status(:bad_request)
        |> render(:bad_request)
    end
  end

  def cart_count(conn, _params) do
    user_id = conn.assigns[:current_user_id]
    count = HtmzPhx.CartManager.get_cart_count(user_id)

    conn
    |> put_root_layout(false)
    |> put_layout(false)
    |> put_resp_content_type("text/plain")
    |> text(Integer.to_string(count))
  end

  def cart_total(conn, _params) do
    user_id = conn.assigns[:current_user_id]
    total = HtmzPhx.CartManager.get_cart_total(user_id)

    conn
    |> put_root_layout(false)
    |> put_layout(false)
    |> put_resp_content_type("text/plain")
    |> text("$#{:erlang.float_to_binary(total, decimals: 2)}")
  end

  def item_details_fragment(conn, %{"item_id" => id}) do
    case Integer.parse(id) do
      {item_id, ""} ->
        case HtmzPhx.GroceryItems.get_grocery_item(item_id) do
          {:ok, item} ->
            # Scale up SVG content to better fit the container and make it fully visible
            scaled_svg =
              item.svg_data
              |> String.replace(~r/width='24' height='24'/, "width='64' height='64'")
              |> String.replace(~r/viewBox='0 0 24 24'/, "viewBox='0 0 24 24'")

            html_content = """
            <div class="text-center">
              <h3 class="text-2xl font-bold text-gray-800 mb-4">#{item.name}</h3>
              <div class="mx-auto mb-4 flex items-center justify-center">
                #{scaled_svg}
              </div>
              <div class="bg-blue-50 rounded-lg p-6 mb-6">
                <p class="text-3xl font-bold text-blue-600">$#{:erlang.float_to_binary(item.price, decimals: 2)}</p>
                <p class="text-gray-600 mt-2">per unit</p>
              </div>
              <button class="w-full bg-blue-600 text-white py-3 px-6 rounded-lg hover:bg-blue-700 transition-colors font-semibold"
                      hx-post="/api/cart/add/#{item.id}"
                      hx-swap="none">
                Add to Cart
              </button>
            </div>
            """

            conn
            |> put_resp_content_type("text/html")
            |> text(html_content)

          {:error, :not_found} ->
            conn
            |> put_status(:not_found)
            |> text("Item not found")
        end

      _ ->
        conn
        |> put_status(:bad_request)
        |> text("Invalid item ID")
    end
  end

  def presence(conn, _params) do
    # TODO: Implement Phoenix Presence count
    # Placeholder
    count = 1

    conn
    |> put_resp_content_type("text/plain")
    |> text(Integer.to_string(count))
  end
end
