// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyAwbitcmOh_YHwpBaHyFQj8CX7MiR6oI6A",
  authDomain: "aivlm-ic.firebaseapp.com",
  databaseURL: "https://aivlm-ic-default-rtdb.firebaseio.com",
  projectId: "aivlm-ic",
  storageBucket: "aivlm-ic.firebasestorage.app",
  messagingSenderId: "682901480654",
  appId: "1:682901480654:web:31a260e79310e2c5e21c9f",
  measurementId: "G-LMKYDW8MGK"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);