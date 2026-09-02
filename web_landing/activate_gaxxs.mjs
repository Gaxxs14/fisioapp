import { initializeApp } from 'firebase/app';
import { getFirestore, doc, updateDoc, deleteDoc, getDoc } from 'firebase/firestore';

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
  await updateDoc(doc(db, "users", targetId), {
    isActive: true
  });
  console.log("Updated cI323ULLETeJPn1utYKNTFJ1CF13 to isActive: true!");

  // Clean up duplicate old doc 6kcF2VVuAlAqYqYzj74x if present
  try {
    await deleteDoc(doc(db, "users", "6kcF2VVuAlAqYqYzj74x"));
    console.log("Deleted old doc 6kcF2VVuAlAqYqYzj74x successfully!");
  } catch (e) {
    console.log("Old doc already deleted or not found");
  }

  const snap = await getDoc(doc(db, "users", targetId));
  console.log("VERIFIED_DATA:", snap.data());
}
run();
