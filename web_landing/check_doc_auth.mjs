import { initializeApp } from 'firebase/app';
import { getFirestore, doc, getDoc, collection, getDocs } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyAKC-XR_xsjOsteN63wPvP2hy9M7i-UWVU",
  authDomain: "fisioapp-df863.firebaseapp.com",
  projectId: "fisioapp-df863",
  storageBucket: "fisioapp-df863.firebasestorage.app",
  messagingSenderId: "793907170712"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function run() {
  const targetId = "cI323ULLETeJPn1utYKNTFJ1CF13";
  const snap = await getDoc(doc(db, "users", targetId));
  if (snap.exists()) {
    console.log("DATA_AT_AUTH_UID:", snap.data());
  } else {
    console.log("NOT_FOUND_AT_AUTH_UID!");
    const all = await getDocs(collection(db, "users"));
    all.forEach(d => console.log(d.id, d.data().username, d.data().isActive));
  }
}
run();
