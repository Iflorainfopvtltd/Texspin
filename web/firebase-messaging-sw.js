importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: 'AIzaSyCoV9Ei5zpE2pD0PDtqa0HQKKj6WQiRZf8',
  authDomain: 'texspin-22abe.firebaseapp.com',
  projectId: 'texspin-22abe',
  messagingSenderId: '873899912878',
  appId: '1:873899912878:web:eb6afb0739f2ed73b4873f',
});

const messaging = firebase.messaging();

// Show background notification
messaging.onBackgroundMessage((payload) => {
  console.log("Background message:", payload);

  const notification = payload.notification;

  self.registration.showNotification(notification.title, {
    body: notification.body,
    icon: "/icons/Icon-192.png",
    data: payload.data, // IMPORTANT: include route here
  });
});

// 🔥 When user clicks notification
self.addEventListener("notificationclick", function (event) {
  event.notification.close();

  const targetUrl = event.notification.data?.route || "/";

  event.waitUntil(
    clients.matchAll({
      type: "window",
      includeUncontrolled: true
    }).then((clientList) => {

      // Focus existing tab if open
      for (const client of clientList) {
        if ("focus" in client) return client.focus();
      }

      // Otherwise open new tab
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});