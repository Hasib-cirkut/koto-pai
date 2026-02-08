import consumer from "channels/consumer"

if (document.body?.dataset?.signedIn === "true") {
  consumer.subscriptions.create("NotificationsChannel", {
    received(data) {
      const container = document.getElementById("notifications")
      if (!container) return

      const item = document.createElement("div")
      item.className =
        "rounded-2xl border border-emerald-500/30 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-100"
      item.innerHTML = `<strong>${data.title}</strong><div class="text-xs mt-1">${data.body}</div>`

      container.prepend(item)
      setTimeout(() => item.remove(), 8000)
    }
  })
}
