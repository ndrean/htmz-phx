defmodule HtmzPhxWeb.PresenceChannel do
  use HtmzPhxWeb, :channel

  alias HtmzPhx.Presence

  @impl true
  def join("presence:lobby", _payload, socket) do
    user_id = socket.assigns.user_id

    send(self(), :after_join)
    {:ok, assign(socket, :user_id, user_id)}
  end

  @impl true
  def handle_info(:after_join, socket) do
    user_id = socket.assigns.user_id

    # Track the user's presence
    {:ok, _} =
      Presence.track(socket, user_id, %{
        online_at: inspect(System.system_time(:second))
      })

    # Broadcast current user count to all connected clients
    broadcast_user_count(socket)

    {:noreply, socket}
  end

  # When presence changes, broadcast the new count
  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    broadcast_user_count(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    # Presence will automatically clean up when socket terminates
    # But let's broadcast the updated count after a small delay to allow cleanup
    spawn(fn ->
      broadcast_user_count(socket)
      HtmzPhx.CartManager.clear_cart(socket.assigns.user_id)
    end)

    :ok
  end

  defp broadcast_user_count(socket) do
    # Count unique user_ids instead of socket connections
    presence_list = Presence.list(socket)
    user_count = presence_list |> Map.keys() |> length()

    broadcast!(socket, "user_count", %{count: user_count})
  end

  # defp generate_user_id do
  #   :crypto.strong_rand_bytes(16) |> Base.encode64()
  # end
end
