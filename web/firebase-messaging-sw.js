/*
  Firebase Cloud Messaging service worker (Flutter Web)
  Place ce fichier à la racine publique (même dossier que index.html)
*/

importScripts(
  "https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js"
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js"
);

// Config issue de lib/firebase_options.dart (section web)
firebase.initializeApp({
  apiKey: "AIzaSyBtrPvf92smtS-sWK-wcHzC1SXPE4gdPkU",
  appId: "1:343645363397:web:7f2f055b1445942feae4ac",
  messagingSenderId: "343645363397",
  projectId: "erp-banamur",
  authDomain: "erp-banamur.firebaseapp.com",
  storageBucket: "erp-banamur.appspot.com",
  measurementId: "G-ZD1M6XSS0L",
});

const messaging = firebase.messaging();

// Optionnel: personnaliser la notification en background
// self.addEventListener('notificationclick', function(event) { /* ... */ });
