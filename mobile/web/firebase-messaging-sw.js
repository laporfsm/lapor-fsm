importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "AIzaSyCUcaNzE1qJHplu2LezLnHJ335VzS_EpuI",
    authDomain: "lapor-fsm.firebaseapp.com",
    projectId: "lapor-fsm",
    storageBucket: "lapor-fsm.firebasestorage.app",
    messagingSenderId: "800333848813",
    appId: "1:800333848813:web:690ccff6068a8bcd232ce4"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    // Customize notification here
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/Icon-192.png'
    };

    self.registration.showNotification(notificationTitle,
        notificationOptions);
});
