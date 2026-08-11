import { initializeApp } from "firebase/app";
import { getFirestore, collection, getDocs, doc, updateDoc } from "firebase/firestore";
import { getAuth, signInWithEmailAndPassword } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyAKC-XR_xsjOsteN63wPvP2hy9M7i-UWVU",
  authDomain: "fisioapp-df863.firebaseapp.com",
  projectId: "fisioapp-df863",
  storageBucket: "fisioapp-df863.firebasestorage.app",
  messagingSenderId: "793907170712"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

async function run() {
  console.log("Iniciando activacion de base de datos...");

  try {
    console.log("Autenticando como Super-Administrador...");
    await signInWithEmailAndPassword(auth, "superadmin@fisioapp.com", "admin1234");
    console.log("Autenticado con exito.");
  } catch (authError) {
    console.error("Error al autenticar:", authError);
    process.exit(1);
  }

  // 1. Activar todas las clinicas y renovar prueba gratuita por 100 anos
  try {
    const clinicsCol = collection(db, "clinics");
    const clinicsSnap = await getDocs(clinicsCol);
    console.log(`Encontradas ${clinicsSnap.docs.length} clinicas.`);

    const hundredYearsFuture = new Date();
    hundredYearsFuture.setFullYear(hundredYearsFuture.getFullYear() + 100);
    const trialEndDateStr = hundredYearsFuture.toISOString();

    for (const clinicDoc of clinicsSnap.docs) {
      const data = clinicDoc.data();
      console.log(`Actualizando clinica: ${data.name || clinicDoc.id}...`);
      await updateDoc(doc(db, "clinics", clinicDoc.id), {
        isActive: true,
        isSubscriptionActive: true,
        paymentStatus: 'approved',
        trialEndDate: trialEndDateStr
      });
      console.log(`Clinica ${clinicDoc.id} activada con exito.`);
    }
  } catch (error) {
    console.error("Error al actualizar clinicas:", error);
  }

  // 2. Activar todos los usuarios y restablecer fecha de cambio de contrasena
  try {
    const usersCol = collection(db, "users");
    const usersSnap = await getDocs(usersCol);
    console.log(`Encontrados ${usersSnap.docs.length} usuarios.`);

    const nowStr = new Date().toISOString();

    for (const userDoc of usersSnap.docs) {
      const data = userDoc.data();
      console.log(`Actualizando usuario: ${data.username || data.email || userDoc.id}...`);
      await updateDoc(doc(db, "users", userDoc.id), {
        isActive: true,
        lastPasswordChange: nowStr
      });
      console.log(`Usuario ${userDoc.id} actualizado con exito.`);
    }
  } catch (error) {
    console.error("Error al actualizar usuarios:", error);
  }

  console.log("Proceso de activacion de base de datos completado con exito!");
  process.exit(0);
}

run();
