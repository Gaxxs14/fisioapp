import { initializeApp } from 'firebase/app';
import { getFirestore, doc, getDoc, collection, getDocs, where, query } from 'firebase/firestore';

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
  const q = query(collection(db, "users"), where("username", "==", "gaxxs"));
  const snap = await getDocs(q);
  console.log(`Found ${snap.docs.length} docs with username gaxxs:`);
  for (const d of snap.docs) {
    const data = d.data();
    console.log(`Doc ID: ${d.id}`, {
      uid: data.uid,
      username: data.username,
      isActive: data.isActive,
      isActiveType: typeof data.isActive,
      pendingAuth: data.pendingAuth,
      role: data.role,
      clinicId: data.clinicId,
      tempPassword: data.tempPassword
    });
  }
}
run();
