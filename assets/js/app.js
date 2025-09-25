import "phoenix_html";
import "../vendor/htmx.min.js";

// window.htmx = require("htmx.org");

// Handle flash close
document.querySelectorAll("[role=alert][data-flash]").forEach((el) => {
  el.addEventListener("click", () => {
    el.setAttribute("hidden", "");
  });
});

// Phoenix Channels for Presence
import { Socket } from "phoenix";

// Only initialize WebSocket connection once per browser session
if (!window.htmzSocket) {
  // Initialize Phoenix Socket with JWT token from cookie
  window.htmzSocket = new Socket("/socket", {
    params: { jwt_token: window.userToken },
  });

  // Connect to the socket
  window.htmzSocket.connect();

  // Join the presence channel once
  const presenceChannel = window.htmzSocket.channel("presence:lobby", {});

  // Handle user count updates and update all presence elements on the page
  presenceChannel.on("user_count", (payload) => {
    document.querySelectorAll("#presence-count").forEach((element) => {
      element.textContent = `Users: ${payload.count}`;
    });
  });

  // Join the channel
  presenceChannel
    .join()
    .receive("ok", (resp) => {
      console.log("Joined presence channel", resp);
    })
    .receive("error", (resp) => {
      console.error("Failed to join presence channel", resp);
    });

  // Store the channel reference
  window.htmzPresenceChannel = presenceChannel;
}

// Clean up on page unload to avoid stale connections
window.addEventListener("beforeunload", () => {
  if (window.htmzPresenceChannel) {
    window.htmzPresenceChannel.leave();
  }
  if (window.htmzSocket) {
    window.htmzSocket.disconnect();
  }
});
