// Scripts for firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker by passing the generated config
const firebaseConfig = {
  apiKey: "AIzaSyB5vvp7IQOZLO7LlsUY_Wq-H8M_5PH3ZQE",
  appId: "1:804273724178:web:c5955a1f657884c0e7f1cb",
  messagingSenderId: "804273724178",
  projectId: "apptaxi-f2190",
  authDomain: "apptaxi-f2190.firebaseapp.com",
  storageBucket: "apptaxi-f2190.firebasestorage.app",
  measurementId: "G-3D8R30TYTM"
};

firebase.initializeApp(firebaseConfig);

// Retrieve firebase messaging
const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('Received background message ', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/favicon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
