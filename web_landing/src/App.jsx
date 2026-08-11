import React, { useState, useEffect } from 'react';
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, doc, setDoc, getDoc, updateDoc, onSnapshot, query, where, getDocs } from 'firebase/firestore';

// 1. Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyAKC-XR_xsjOsteN63wPvP2hy9M7i-UWVU",
  authDomain: "fisioapp-df863.firebaseapp.com",
  projectId: "fisioapp-df863",
  storageBucket: "fisioapp-df863.firebasestorage.app",
  messagingSenderId: "793907170712"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// 2. Translation dictionary
const translations = {
  es: {
    loaderText: "Iniciando FisioApp...",
    navFeatures: "Características",
    navStats: "Estadísticas",
    navPricing: "Precios",
    navTestimonials: "Opiniones",
    navFaq: "Preguntas Frecuentes",
    btnCtaNav: "Comenzar Gratis",
    heroTagline: "🚀 Lanzamiento Oficial SaaS 2026",
    heroTitle: "Lleva tu clínica de fisioterapia al <span>siguiente nivel</span>",
    heroSubtitle: "La plataforma integral más rápida para gestionar agendas de citas, redactar expedientes SOAP estructurados con escala EVA, firmar consentimientos legales y automatizar cobros.",
    btnHeroCta: "Comenzar Prueba Gratis (14 días)",
    btnHeroSecondary: "Explorar Módulos",
    mockupSidebarDashboard: "📊 Dashboard",
    mockupSidebarAgenda: "📅 Agenda",
    mockupSidebarPacientes: "👥 Pacientes",
    mockupSidebarCobranza: "💰 Cobranza",
    mockupSidebarConfig: "⚙️ Configuración",
    mockupKpiRevenue: "Ingresos Mensuales",
    mockupKpiRevenueTrend: "▲ +14% vs mes anterior",
    mockupKpiPatients: "Pacientes Activos",
    mockupKpiPatientsTrend: "▲ +28 nuevos este mes",
    mockupKpiSessions: "Citas Completadas",
    mockupKpiSessionsTrend: "● 92% asistencia",
    mockupChartHeader: "Evolución de Sesiones Diarias",
    dayMon: "Lun", dayTue: "Mar", dayWed: "Mié", dayThu: "Jue", dayFri: "Vie", daySat: "Sáb",
    mockupAgendaHeaderTitle: "Miércoles, 8 de Julio",
    mockupAgendaToday: "Hoy",
    mockupAgendaCard1: "Fisioterapia Deportiva (Box 1)",
    mockupAgendaCard2: "Rehabilitación Post-Quirúrgica (Box 3)",
    mockupAgendaCard3: "Evaluación Inicial (Box 2)",
    mockupSearchPlaceholder: "🔍 Buscar paciente por nombre o DNI...",
    mockupPatientBadge1: "Firma OK",
    mockupPatientBadge2: "SOAP Completado",
    mockupPatientBadge3: "Pendiente EVA",
    mockupKpiDaily: "Recaudado Hoy",
    mockupKpiDailyTrend: "Caja Abierta (Cuadre OK)",
    mockupKpiDebts: "Cuentas Pendientes",
    mockupKpiDebtsTrend: "2 facturas por cobrar",
    mockupKpiPacks: "Bonos Vendidos",
    mockupKpiPacksTrend: "Este mes",
    mockupPayRow1: "Sesión Deportiva - Carlos Pérez",
    mockupPayRow2: "Bono 10 Sesiones - Ana Gómez",
    mockupSetBiometricsTitle: "Acceso Biométrico",
    mockupSetBiometricsDesc: "Permitir huella digital para login rápido",
    mockupSetPushTitle: "Notificaciones Push",
    mockupSetPushDesc: "Enviar alertas a la aplicación del paciente",
    mockupSetLangTitle: "Idioma Predeterminado",
    mockupSetLangDesc: "Selección del idioma del sistema",
    spanish: "Español",
    featuresTitle: "Diseñado por fisioterapeutas, para fisioterapeutas",
    featuresSubtitle: "Elimina el papeleo y enfócate en lo que mejor sabes hacer: recuperar la salud de tus pacientes.",
    featCardTitle1: "Agenda Inteligente Multi-Vista",
    featCardDesc1: "Visualiza el calendario por día, semana, mes o por profesional. Controla el inventario de camillas y box de atención en tiempo real.",
    featCard1Bullet1: "Vista de calendario adaptable por día, semana y mes.",
    featCard1Bullet2: "Bloqueo automático de colisiones y duplicados de horario.",
    featCard1Bullet3: "Asignación de salas de tratamiento y camillas específicas.",
    featCard1Bullet4: "Lista de espera activa para rellenar huecos cancelados.",
    featCardTitle2: "Expediente SOAP y Plantillas",
    featCardDesc2: "Escribe notas subjetivas, objetivas, evaluaciones y planes de tratamiento en segundos. Guarda plantillas por patología.",
    featCard2Bullet1: "Formulario SOAP estructurado: Subjetivo, Objetivo, Análisis, Plan.",
    featCard2Bullet2: "Base de datos para autoguardar plantillas por patología.",
    featCard2Bullet3: "Gráfica de evolución EVA y Daniels integrada.",
    featCard2Bullet4: "Notas internas privadas visibles solo para el personal clínico.",
    featCardTitle3: "Firma Consentida de Pacientes",
    featCardDesc3: "Tus pacientes firman consentimientos informados desde la app o tablet, guardándose de forma segura como PDF clínico inalterable.",
    featCard3Bullet1: "Panel táctil de dibujo de firma de alta precisión.",
    featCard3Bullet2: "Generación automática de PDFs con DNI y marca de tiempo.",
    featCard3Bullet3: "Almacenamiento e historial de firmas digital encriptado.",
    featCard3Bullet4: "Exportación inmediata en PDF para fines legales o auditorías.",
    featCardTitle4: "Cobros y Paquetes de Bonos",
    featCardDesc4: "Registra ingresos en efectivo, tarjeta o transferencia. Vende bonos de sesiones y descuéntalos de manera automática.",
    featCard4Bullet1: "Módulo de registro contable de pagos del día.",
    featCard4Bullet2: "Gestión de saldos deudores y facturas pendientes.",
    featCard4Bullet3: "Venta y control de bonos o paquetes de sesiones prepagadas.",
    featCard4Bullet4: "Cierre de caja diario con cuadre manual y reporte en la nube.",
    featCardTitle5: "Reportes de Rendimiento",
    featCardDesc5: "Exporta toda tu contabilidad, listado de pacientes e historiales a documentos de Excel y PDF con un solo clic.",
    featCard5Bullet1: "Exportación a plantillas Excel multi-pestaña automatizada.",
    featCard5Bullet2: "Gráficos de ingresos desglosados por tipo de servicio.",
    featCard5Bullet3: "Tasa de ausentismo con recomendaciones operativas automáticas.",
    featCard5Bullet4: "Descarga completa del expediente del paciente en formato PDF.",
    featCardTitle6: "Portal del Paciente y FCM",
    featCardDesc6: "Tus pacientes tienen su propia app para ver sus citas, consultar comunicados de la clínica y recibir alertas push.",
    featCard6Bullet1: "App web para que los pacientes revisen su agenda de citas.",
    featCard6Bullet2: "Buzón de avisos, comunicados y campañas de salud masivas.",
    featCard6Bullet3: "Banners emergentes interactivos (Foreground) mientras usan la app.",
    featCard6Bullet4: "Envío de notificaciones push nativas al celular (FCM).",
    viewDetails: "Ver más detalles ➔",
    closeDetails: "Cerrar detalles ✖",
    statLabel1: "Consultas Clínicas Registradas",
    statLabel2: "Disponibilidad del Sistema (Uptime)",
    statNumber3: "14 Días",
    statLabel3: "Prueba Gratuita Sin Compromiso",
    statLabel4: "Calificación de Profesionales",
    pricingTitle: "Elige el plan ideal para tu clínica",
    pricingSubtitle: "Precios transparentes y sin sorpresas. Todos los planes incluyen actualizaciones continuas y soporte técnico.",
    plan1Title: "Plan Básico",
    plan1Desc: "Perfecto para profesionales independientes o consultorios que recién inician.",
    pricePeriod: "/ mes",
    plan1Feature1: "Hasta 2 fisioterapeutas/personal",
    plan1Feature2: "Agenda y Calendario Completo",
    plan1Feature3: "Hasta 150 expedientes de pacientes",
    plan1Feature4: "Historia clínica y SOAP básico",
    plan1Feature5: "Soporte vía correo electrónico",
    btnPlan1: "Elegir Plan Básico",
    badgeFeatured: "Recomendado",
    plan2Title: "Plan Profesional",
    plan2Desc: "La solución completa para clínicas consolidadas que necesitan facturar y firmar.",
    plan2Feature1: "Terapeutas y personal ilimitados",
    plan2Feature2: "Pacientes y expedientes ilimitados",
    plan2Feature3: "Módulo de Firma Digital y EVA",
    plan2Feature4: "Módulo de Cobranza diario y Bonos",
    plan2Feature5: "Exportación a Excel y PDF Clínico",
    plan2Feature6: "Notificaciones en app del paciente",
    btnPlan2: "Elegir Plan Profesional",
    plan3Title: "Plan Enterprise",
    plan3Desc: "Para franquicias o redes de centros de rehabilitación multi-sucursal.",
    plan3Feature1: "Todo lo del Plan Profesional",
    plan3Feature2: "Multi-sucursal (Gestión unificada)",
    plan3Feature3: "Acceso a API de integración",
    plan3Feature4: "Personalizaciones bajo demanda",
    plan3Feature5: "Soporte técnico prioritario 24/7",
    plan3Feature6: "Gerente de cuenta dedicado",
    btnPlan3: "Elegir Plan Enterprise",
    testimonialsTitle: "Lo que dicen las clínicas asociadas",
    testimonialsSubtitle: "Cientos de fisioterapeutas ya confían en FisioApp para organizar sus operaciones diarias.",
    review1Text: "\"FisioApp nos salvó de perder hojas físicas de expedientes. La firma digital en la tablet ha agilizado un 40% el ingreso de pacientes.\"",
    review1Role: "Directora de FisioHealth",
    review2Text: "\"El sistema de bonos y cobranza diaria nos permite cuadrar la caja en menos de 5 minutos al final del día laboral. Una maravilla.\"",
    review2Role: "Fundador de KineCenter",
    faqTitle: "Preguntas Frecuentes",
    faqSubtitle: "¿Tienes dudas? Aquí te respondemos las preguntas más comunes sobre FisioApp.",
    faqQ1: "¿Necesito ingresar mi tarjeta de crédito para la prueba gratuita?",
    faqA1: "No, puedes registrarte y disfrutar del acceso completo a todas las funciones del Plan Profesional durante 14 días sin ingresar ningún método de pago.",
    faqQ2: "¿Los expedientes y firmas digitales tienen validez legal?",
    faqA2: "Sí, la firma digital registrada junto a la fecha y los datos únicos del paciente cumple con los estándares exigidos para el consentimiento informado clínico.",
    faqQ3: "¿Cómo accedo a la aplicación móvil una vez me registre?",
    faqA3: "Tras completar el formulario en esta web, verás una pantalla de éxito con las credenciales de tu clínica y un botón de descarga para bajar la app (APK) en tu tablet o celular.",
    faqQ4: "¿Puedo cambiar de plan o cancelar en cualquier momento?",
    faqA4: "Sí, no tenemos contratos de permanencia obligatorios. Puedes cambiar tu plan o cancelar tu suscripción mensual en cualquier momento desde tu panel de administrador.",
    modalTitle: "Registrar Clínica",
    modalSubtitle: "Completa los datos para iniciar tu prueba gratuita de 14 días del software. No requieres tarjeta.",
    labelClinicName: "Nombre de la Clínica",
    phClinicName: "Ej: Clínica de Rehabilitación FisioLife",
    labelAdminName: "Nombre Completo del Administrador",
    phAdminName: "Ej: Dr. Alejandro Mendoza",
    labelUsername: "Nombre de Usuario para Login",
    phUsername: "Ej: alejandrom",
    labelEmail: "Correo Electrónico de Contacto",
    phEmail: "Ej: contacto@clinica.com",
    labelPassword: "Contraseña (Mínimo 6 caracteres)",
    labelSecurityQ: "Pregunta de Seguridad (Para recuperar contraseña)",
    optSelectQ: "Selecciona una pregunta...",
    optQ1: "¿Cuál es tu color favorito?",
    optQ2: "¿Cuál es el nombre de tu primera mascota?",
    optQ3: "¿En qué ciudad naciste?",
    optQ4: "¿Cuál es tu comida favorita?",
    labelSecurityA: "Respuesta de Seguridad",
    phSecurityA: "Tu respuesta secreta",
    btnRegister: "Comenzar Prueba Gratis",
    successTitle: "¡Clínica Registrada con Éxito!",
    successIntroPart1: "Hemos creado y configurado la base de datos para tu clínica",
    successIntroPart2: "de manera correcta. Tu periodo de prueba de 14 días ha comenzado.",
    successCredsSentTitle: "📧 Credenciales Enviadas",
    successCredsSentDesc: "Hemos enviado un correo a <strong id=\"successEmail\"></strong> con tu nombre de usuario, contraseña temporal y las instrucciones para iniciar sesión.",
    successDownloadTitle: "Paso Siguiente: Descarga la Aplicación",
    successDownloadDesc: "Inicia sesión en la tablet o celular de tu clínica usando las credenciales enviadas para comenzar a operar.",
    btnDownloadApk: "Descargar FisioApp APK",
    footerText: "© 2026 FisioApp. Todos los derechos reservados. Gestión clínica e historia digital para profesionales.",
    navContact: "Contacto",
    contactTitle: "Contáctanos",
    contactSubtitle: "¿Tienes dudas o deseas una demostración personalizada? Escríbenos y te responderemos en minutos.",
    contactInfoEmail: "Correo Electrónico",
    contactInfoEmailDesc: "Envíanos tus consultas técnicas o comerciales.",
    contactLabelName: "Tu Nombre",
    contactLabelMsg: "Mensaje",
    phLeadMsg: "Escribe tu mensaje o pregunta aquí...",
    btnSendMessage: "Enviar Mensaje"
  },
  en: {
    loaderText: "Starting FisioApp...",
    navFeatures: "Features",
    navStats: "Statistics",
    navPricing: "Pricing",
    navTestimonials: "Reviews",
    navFaq: "FAQ",
    btnCtaNav: "Get Started Free",
    heroTagline: "🚀 Official SaaS Launch 2026",
    heroTitle: "Take your physiotherapy clinic to the <span>next level</span>",
    heroSubtitle: "The fastest comprehensive platform to manage appointments, write structured SOAP clinical records with visual pain scales, sign consent forms, and automate billing.",
    btnHeroCta: "Start Free Trial (14 days)",
    btnHeroSecondary: "Explore Modules",
    mockupSidebarDashboard: "📊 Dashboard",
    mockupSidebarAgenda: "📅 Schedule",
    mockupSidebarPacientes: "👥 Patients",
    mockupSidebarCobranza: "💰 Billing",
    mockupSidebarConfig: "⚙️ Settings",
    mockupKpiRevenue: "Monthly Revenue",
    mockupKpiRevenueTrend: "▲ +14% vs last month",
    mockupKpiPatients: "Active Patients",
    mockupKpiPatientsTrend: "▲ +28 new this month",
    mockupKpiSessions: "Completed Sessions",
    mockupKpiSessionsTrend: "● 92% attendance",
    mockupChartHeader: "Daily Sessions Overview",
    dayMon: "Mon", dayTue: "Tue", dayWed: "Wed", dayThu: "Thu", dayFri: "Fri", daySat: "Sat",
    mockupAgendaHeaderTitle: "Wednesday, July 8th",
    mockupAgendaToday: "Today",
    mockupAgendaCard1: "Sports Physiotherapy (Box 1)",
    mockupAgendaCard2: "Post-Surgical Rehab (Box 3)",
    mockupAgendaCard3: "Initial Evaluation (Box 2)",
    mockupSearchPlaceholder: "🔍 Search patient by name or DNI...",
    mockupPatientBadge1: "Signed OK",
    mockupPatientBadge2: "SOAP Complete",
    mockupPatientBadge3: "Pending Pain Scale",
    mockupKpiDaily: "Collected Today",
    mockupKpiDailyTrend: "Register Open (Balanced OK)",
    mockupKpiDebts: "Pending Balances",
    mockupKpiDebtsTrend: "2 bills to collect",
    mockupKpiPacks: "Packages Sold",
    mockupKpiPacksTrend: "This month",
    mockupPayRow1: "Sports Session - Carlos Pérez",
    mockupPayRow2: "10-Session Package - Ana Gómez",
    mockupSetBiometricsTitle: "Biometric Access",
    mockupSetBiometricsDesc: "Allow fingerprint scan for quick login",
    mockupSetPushTitle: "Push Notifications",
    mockupSetPushDesc: "Send real-time alerts to patients",
    mockupSetLangTitle: "Default Language",
    mockupSetLangDesc: "Select application default language",
    spanish: "English",
    featuresTitle: "Designed by therapists, for therapists",
    featuresSubtitle: "Ditch the paperwork and focus on what you do best: helping your patients recover.",
    featCardTitle1: "Multi-View Smart Scheduler",
    featCardDesc1: "View calendar by day, week, month or therapist. Track box and treatment table availability in real time.",
    featCard1Bullet1: "Flexible calendar layouts adjusted by day, week, and month.",
    featCard1Bullet2: "Automatic overlap prevention and scheduling safety guards.",
    featCard1Bullet3: "Assign dedicated treatment rooms and specific physical tables.",
    featCard1Bullet4: "Integrated waiting list to automatically fill cancelled slots.",
    featCardTitle2: "SOAP Records & Templates",
    featCardDesc2: "Write subjective, objective, assessments, and plans in seconds. Build reusable templates by pathology.",
    featCard2Bullet1: "Structured SOAP form: Subjective, Objective, Assessment, Plan.",
    featCard2Bullet2: "Save custom templates library for Sprains, Scoliosis, etc.",
    featCard2Bullet3: "Integrated EVA pain chart and Daniels muscular strength scale.",
    featCard2Bullet4: "Private internal clinical notes hidden from patients.",
    featCardTitle3: "Digital Consent Signing",
    featCardDesc3: "Patients sign consent documents directly on mobile or tablet, generating secure unalterable clinical PDFs.",
    featCard3Bullet1: "High-precision digital signature drawing board.",
    featCard3Bullet2: "Automatic PDF generation with ID and timestamp.",
    featCard3Bullet3: "Encrypted history archive for signed files.",
    featCard3Bullet4: "Instant PDF export for regulatory and auditing purposes.",
    featCardTitle4: "Collections & Prepaid Packages",
    featCardDesc4: "Register cash, credit cards, or transfers. Sell session bundles and deduct them automatically.",
    featCard4Bullet1: "Daily accounting billing ledger module.",
    featCard4Bullet2: "Track pending balances and accounts receivable.",
    featCard4Bullet3: "Sell and manage prepaid session packages (eg. 10-packs).",
    featCard4Bullet4: "End-of-day register closure reports stored in the cloud.",
    featCardTitle5: "Performance Analytics",
    featCardDesc5: "Export accounts, patients charts, and clinical records to Excel or PDF in a single click.",
    featCard5Bullet1: "Automatic multi-tab Excel spreadsheet reporting.",
    featCard5Bullet2: "Visual revenue breakdown charts by clinical service type.",
    featCard5Bullet3: "Attendance rate reports and automatic business tips.",
    featCard5Bullet4: "Download comprehensive patient clinical file as PDF.",
    featCardTitle6: "Patient Portal & FCM Alerting",
    featCardDesc6: "Patients download their own app to check appointments, view clinic messages, and receive push alerts.",
    featCard6Bullet1: "Patient web panel to manage appointment schedules.",
    featCard6Bullet2: "Receive mass updates, clinic announcements, and tips.",
    featCard6Bullet3: "Interactive floating banners while app is open.",
    featCard6Bullet4: "Receive native device push alerts in real-time (FCM).",
    viewDetails: "View details ➔",
    closeDetails: "Close details ✖",
    statLabel1: "Clinical Consultations Logged",
    statLabel2: "System Uptime Guarantee",
    statNumber3: "14 Days",
    statLabel3: "Free Trial Without Commitment",
    statLabel4: "Therapists Rating Score",
    pricingTitle: "Choose the right plan for your clinic",
    pricingSubtitle: "Clear pricing structure, no hidden fees. All plans include continuous updates and technical support.",
    plan1Title: "Basic Plan",
    plan1Desc: "Perfect for independent therapists or clinics just getting started.",
    pricePeriod: "/ month",
    plan1Feature1: "Up to 2 therapists / staff members",
    plan1Feature2: "Full Calendar and Scheduler",
    plan1Feature3: "Up to 150 patient records",
    plan1Feature4: "Basic clinical history & SOAP notes",
    plan1Feature5: "Email ticketing customer support",
    btnPlan1: "Choose Basic Plan",
    badgeFeatured: "Recommended",
    plan2Title: "Professional Plan",
    plan2Desc: "The complete package for clinics that need digital signature and collections.",
    plan2Feature1: "Unlimited therapists & staff members",
    plan2Feature2: "Unlimited patients & records",
    plan2Feature3: "EVA Pain Scale & Digital Signature",
    plan2Feature4: "Billing Ledger & Session Packages",
    plan2Feature5: "Export clinical PDFs and Excel reports",
    plan2Feature6: "Patient App & Push Alerts integration",
    btnPlan2: "Choose Professional Plan",
    plan3Title: "Enterprise Plan",
    plan3Desc: "Built for multi-location clinic networks with custom needs.",
    plan3Feature1: "All features in Professional Plan",
    plan3Feature2: "Multi-branch clinic portal",
    plan3Feature3: "API integration access keys",
    plan3Feature4: "On-demand visual customizations",
    plan3Feature5: "Priority 24/7 technical hotline",
    plan3Feature6: "Dedicated Customer Success Manager",
    btnPlan3: "Choose Enterprise Plan",
    testimonialsTitle: "What clinic directors say about us",
    testimonialsSubtitle: "Hundreds of physiotherapy clinics already trust FisioApp for daily scheduling.",
    review1Text: "\"FisioApp saved us from losing physical patient folders. Signing consent forms on tablets cut patient intake time by 40%.\"",
    review1Role: "Medical Director at FisioHealth",
    review2Text: "\"The billing ledger and package tracking lets us balance the daily register in less than 5 minutes. Amazing software.\"",
    review2Role: "Founder of KineCenter",
    faqTitle: "Frequently Asked Questions",
    faqSubtitle: "Have questions? Here are the most common inquiries about FisioApp.",
    faqQ1: "Do I need to enter a credit card for the free trial?",
    faqA1: "No, you can sign up and try all Professional Plan features for 14 days without inputting any billing method.",
    faqQ2: "Are the digital consent signatures legally binding?",
    faqA2: "Yes, the digital signatures captured alongside patient ID metadata and timestamps comply with clinical consent regulations.",
    faqQ3: "How do I access the mobile app after registering?",
    faqA3: "Upon signing up, you will see a success screen with your credentials and a download button for the clinic tablet app (APK).",
    faqQ4: "Can I upgrade, downgrade or cancel at any time?",
    faqA4: "Yes, there are no lock-in contracts. You can switch plans or cancel your monthly subscription whenever you want from the admin panel.",
    modalTitle: "Register Clinic",
    modalSubtitle: "Fill in the details to start your 14-day free trial. No card required.",
    labelClinicName: "Clinic Name",
    phClinicName: "e.g. FisioLife Rehabilitation Center",
    labelAdminName: "Administrator Full Name",
    phAdminName: "e.g. Dr. Alejandro Mendoza",
    labelUsername: "Login Username",
    phUsername: "e.g. alejandrom",
    labelEmail: "Contact Email Address",
    phEmail: "e.g. contact@clinic.com",
    labelPassword: "Password (Min. 6 characters)",
    labelSecurityQ: "Security Question (For password recovery)",
    optSelectQ: "Choose a question...",
    optQ1: "What is your favorite color?",
    optQ2: "What is your first pet's name?",
    optQ3: "In which city were you born?",
    optQ4: "What is your favorite food?",
    labelSecurityA: "Security Answer",
    phSecurityA: "Your secret answer",
    btnRegister: "Start Free Trial",
    successTitle: "Clinic Registered Successfully!",
    successIntroPart1: "We have created and configured the database for your clinic",
    successIntroPart2: "properly. Your 14-day free trial period has started.",
    successCredsSentTitle: "📧 Credentials Sent",
    successCredsSentDesc: "We have sent an email to <strong id=\"successEmail\"></strong> containing your login username, temporary password, and instructions.",
    successDownloadTitle: "Next Step: Download the Mobile App",
    successDownloadDesc: "Log in on your clinic phone or tablet using the credentials sent to your email to start operating.",
    btnDownloadApk: "Download FisioApp APK",
    footerText: "© 2026 FisioApp. All rights reserved. Clinic management and digital charts for professionals.",
    navContact: "Contact",
    contactTitle: "Contact Us",
    contactSubtitle: "Have questions or want a custom demo? Write to us and we'll reply in minutes.",
    contactInfoEmail: "Email Support",
    contactInfoEmailDesc: "Send us your technical or commercial inquiries.",
    contactLabelName: "Your Name",
    contactLabelMsg: "Message",
    phLeadMsg: "Write your message or question here...",
    btnSendMessage: "Send Message"
  }
};

export default function App() {
  const [lang, setLang] = useState(localStorage.getItem('lang') || 'es');
  const [theme, setTheme] = useState(localStorage.getItem('theme') || 'dark');
  const [loading, setLoading] = useState(true);
  
  // Tabs for the interactive mockup dashboard
  const [activeTab, setActiveTab] = useState('dashboard');
  
  // Collapsed features details
  const [expandedFeatures, setExpandedFeatures] = useState({
    agenda: false,
    expediente: false,
    firma: false,
    cobranza: false,
    reportes: false,
    portal: false
  });

  // Billing Cycle Toggle (Mensual / Anual)
  const [billingCycle, setBillingCycle] = useState('monthly');
  
  // Registration Wizard Step (1: Credentials, 2: Payment)
  const [regStep, setRegStep] = useState(1);
  const [regPayMethod, setRegPayMethod] = useState('pagomovil');

  // FAQs active states
  const [activeFaq, setActiveFaq] = useState([false, false, false, false]);

  // Super Admin View and Actions state
  const [currentView, setCurrentView] = useState('landing');
  const [adminLoggedIn, setAdminLoggedIn] = useState(false);
  const [adminPassword, setAdminPassword] = useState('');
  const [adminError, setAdminError] = useState('');
  const [clinics, setClinics] = useState([]);
  const [loadingClinics, setLoadingClinics] = useState(false);
  const [updatingClinicId, setUpdatingClinicId] = useState(null);
  const [adminSearch, setAdminSearch] = useState('');

  // Check URL parameters for admin page access
  useEffect(() => {
    if (window.location.search.includes('admin=true') || window.location.pathname.includes('/superadmin')) {
      setCurrentView('superadmin');
    }
  }, []);

  // Modal and Signup status
  const [modalOpen, setModalOpen] = useState(false);
  const [successOpen, setSuccessOpen] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState('');
  const [registeredEmail, setRegisteredEmail] = useState('');
  const [registeredClinic, setRegisteredClinic] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formError, setFormError] = useState('');

  // Contact Form Leads status
  const [leadName, setLeadName] = useState('');
  const [leadEmail, setLeadEmail] = useState('');
  const [leadMessage, setLeadMessage] = useState('');
  const [leadFeedback, setLeadFeedback] = useState('');
  const [isLeadSubmitting, setIsLeadSubmitting] = useState(false);

  // Auto-hide page loader
  useEffect(() => {
    const timer = setTimeout(() => {
      setLoading(false);
    }, 1800);
    return () => clearTimeout(timer);
  }, []);

  // Update theme class on HTML element
  useEffect(() => {
    if (theme === 'light') {
      document.body.classList.add('light-theme');
    } else {
      document.body.classList.remove('light-theme');
    }
    localStorage.setItem('theme', theme);
  }, [theme]);

  const handleLanguageSelect = (selected) => {
    setLang(selected);
    localStorage.setItem('lang', selected);
  };

  const toggleTheme = () => {
    setTheme(prev => prev === 'dark' ? 'light' : 'dark');
  };

  const toggleFeature = (name) => {
    setExpandedFeatures(prev => ({
      ...prev,
      [name]: !prev[name]
    }));
  };

  const toggleFaqItem = (index) => {
    setActiveFaq(prev => {
      const copy = [...prev];
      copy[index] = !copy[index];
      return copy;
    });
  };

  const openRegisterModal = (planName) => {
    setSelectedPlan(planName);
    setFormError('');
    setModalOpen(true);
  };

  // Submit signup data to Firestore
  const handleRegisterSubmit = async (e) => {
    e.preventDefault();
    setFormError('');
    setIsSubmitting(true);

    const clinicName = e.target.clinicName.value;
    const adminName = e.target.adminName.value;
    const username = e.target.username.value.trim().toLowerCase();
    const email = e.target.email.value.trim().toLowerCase();
    const password = e.target.password.value;
    const securityQuestion = e.target.securityQuestion.value;
    const securityAnswer = e.target.securityAnswer.value.trim();

    if (password.length < 6) {
      setFormError(lang === 'es' ? "La contraseña debe tener al menos 6 caracteres." : "Password must be at least 6 characters.");
      setIsSubmitting(false);
      return;
    }

    const paymentReference = e.target.paymentReference ? e.target.paymentReference.value.trim() : '';

    try {
      // 1. Create unique clinic document
      const clinicId = "clinic_" + Math.random().toString(36).substring(2, 11);
      const clinicDocRef = doc(db, "clinics", clinicId);
      await setDoc(clinicDocRef, {
        name: clinicName,
        plan: selectedPlan,
        createdAt: new Date().toISOString(),
        isActive: true, // Auto-active for free trial mode
        paymentStatus: 'approved', // Auto-approved for free trial mode
        paymentMethod: regPayMethod || 'free_trial',
        paymentReference: paymentReference || 'free',
        billingCycle: billingCycle,
        trialEndDate: new Date(new Date().setFullYear(new Date().getFullYear() + 100)).toISOString(), // 100 years
        isSubscriptionActive: true
      });

      // 2. Create administrator user document
      const adminDocRef = doc(collection(db, "users"));
      const adminUid = adminDocRef.id;
      const now = new Date();
      const adminData = {
        uid: adminUid,
        username: username,
        email: email,
        name: adminName,
        clinicId: clinicId,
        role: "admin",
        createdAt: now.toISOString(),
        lastPasswordChange: now.toISOString(),
        isActive: true,
        pendingAuth: true,
        tempPassword: password,
        securityQuestions: {
          question: securityQuestion,
          answer_hashed: securityAnswer
        }
      };
      await setDoc(adminDocRef, adminData);

      // 3. Create mail document for Trigger Email Extension
      const mailDocRef = doc(collection(db, "mail"));
      const emailContent = `
        <h3>¡Tu Clínica está Activa - FisioApp!</h3>
        <p>Hemos registrado tu clínica <strong>${clinicName}</strong> con éxito.</p>
        <p>Tu cuenta ha sido activada de forma totalmente gratuita. Ya puedes iniciar sesión de forma inmediata.</p>
        <hr>
        <p><strong>Tus Credenciales de Acceso Temporales:</strong></p>
        <ul>
          <li><strong>Nombre de Usuario (Login):</strong> ${username}</li>
          <li><strong>Contraseña Temporal:</strong> ${password}</li>
          <li><strong>Rol de Usuario:</strong> Administrador Clínico</li>
        </ul>
        <hr>
        <p><strong>Siguiente Paso: Descargar la Aplicación</strong></p>
        <p>Descarga la aplicación en tu tableta o teléfono Android desde aquí para empezar a usar el sistema:</p>
        <p><a href="https://firebasestorage.googleapis.com/v1/b/fisioapp-df863.firebasestorage.app/o/fisioapp.apk?alt=media" style="display:inline-block; background:#14B8A6; color:white; padding:10px 20px; text-decoration:none; border-radius:30px; font-weight:bold;">Descargar FisioApp APK</a></p>
        <br>
        <p>Si tienes alguna duda o necesitas asistencia, escríbenos a este correo.</p>
        <p>Atentamente,<br><strong>El Equipo de FisioApp</strong></p>
      `;
      
      await setDoc(mailDocRef, {
        to: email,
        message: {
          subject: "¡Clínica Activada con Éxito! - FisioApp",
          html: emailContent
        }
      });

      // 4. Update UI
      setRegisteredEmail(email);
      setRegisteredClinic(clinicName);
      setModalOpen(false);
      setSuccessOpen(true);
    } catch (err) {
      console.error(err);
      setFormError(lang === 'es' ? "Ocurrió un error en el servidor. Inténtalo de nuevo." : "Server error occurred. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  // Submit Lead to Firestore
  const handleLeadSubmit = async (e) => {
    e.preventDefault();
    setLeadFeedback('');
    setIsLeadSubmitting(true);

    try {
      const leadDocRef = doc(collection(db, "leads"));
      await setDoc(leadDocRef, {
        name: leadName,
        email: leadEmail,
        message: leadMessage,
        createdAt: new Date().toISOString()
      });
      setLeadFeedback(lang === 'es' ? "¡Mensaje enviado con éxito! Te responderemos muy pronto." : "Message sent successfully! We will get back to you soon.");
      setLeadName('');
      setLeadEmail('');
      setLeadMessage('');
    } catch (err) {
      console.error(err);
      setLeadFeedback(lang === 'es' ? "Error al enviar el mensaje. Inténtalo de nuevo." : "Error sending message. Please try again.");
    } finally {
      setIsLeadSubmitting(false);
    }
  };

  // Super Admin view logic
  const handleAdminLogin = async (e) => {
    e.preventDefault();
    setAdminError('');
    try {
      // Query firestore users collection for superadmin
      const adminDocRef = doc(db, "users", "superadmin");
      const adminDoc = await getDoc(adminDocRef);
      
      if (adminDoc.exists()) {
        const adminData = adminDoc.data();
        if (adminData.tempPassword === adminPassword) {
          setAdminLoggedIn(true);
          localStorage.setItem('superadmin_logged_in', 'true');
        } else if (adminPassword === 'admin1234') {
          // If password was reset or changed but user wants to boot/seed with admin1234
          try {
            await setDoc(adminDocRef, {
              uid: "superadmin",
              username: "superadmin",
              role: "superadmin",
              tempPassword: "admin1234",
              email: "superadmin@fisioapp.com",
              pendingAuth: true,
              createdAt: new Date().toISOString()
            });
          } catch (e) {
            console.error("Failed to seed superadmin doc:", e);
          }
          setAdminLoggedIn(true);
          localStorage.setItem('superadmin_logged_in', 'true');
        } else {
          setAdminError(lang === 'es' ? 'Contraseña de administrador incorrecta.' : 'Incorrect admin password.');
        }
      } else {
        // Fallback password for bootstrapping when the document does not exist yet
        if (adminPassword === 'admin1234') {
          try {
            await setDoc(adminDocRef, {
              uid: "superadmin",
              username: "superadmin",
              role: "superadmin",
              tempPassword: "admin1234",
              email: "superadmin@fisioapp.com",
              pendingAuth: true,
              createdAt: new Date().toISOString()
            });
          } catch (e) {
            console.error("Failed to seed superadmin doc:", e);
          }
          setAdminLoggedIn(true);
          localStorage.setItem('superadmin_logged_in', 'true');
        } else {
          setAdminError(lang === 'es' ? 'No se pudo verificar el usuario superadmin.' : 'Could not verify superadmin user.');
        }
      }
    } catch (err) {
      console.error(err);
      setAdminError(lang === 'es' ? 'Error al iniciar sesión.' : 'Error logging in.');
    }
  };

  const handleAdminLogout = () => {
    setAdminLoggedIn(false);
    localStorage.removeItem('superadmin_logged_in');
  };

  // Check login state on mount
  useEffect(() => {
    if (localStorage.getItem('superadmin_logged_in') === 'true') {
      setAdminLoggedIn(true);
    }
  }, []);

  // Fetch clinics list in real time
  useEffect(() => {
    if (adminLoggedIn && currentView === 'superadmin') {
      setLoadingClinics(true);
      const unsubscribe = onSnapshot(collection(db, "clinics"), 
        (snapshot) => {
          const list = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
          // Sort by creation date descending
          list.sort((a, b) => {
            const aDate = a.createdAt ? new Date(a.createdAt) : new Date(0);
            const bDate = b.createdAt ? new Date(b.createdAt) : new Date(0);
            return bDate - aDate;
          });
          setClinics(list);
          setLoadingClinics(false);
        },
        (err) => {
          console.error(err);
          setLoadingClinics(false);
        }
      );
      return () => unsubscribe();
    }
  }, [adminLoggedIn, currentView]);

  const toggleClinicActive = async (clinicId, currentActive) => {
    setUpdatingClinicId(clinicId);
    try {
      const nextActive = !currentActive;
      const hundredYearsFuture = new Date();
      hundredYearsFuture.setFullYear(hundredYearsFuture.getFullYear() + 100);
      const trialEndDateStr = hundredYearsFuture.toISOString();

      await updateDoc(doc(db, "clinics", clinicId), {
        isActive: nextActive,
        isSubscriptionActive: nextActive,
        paymentStatus: nextActive ? 'approved' : 'suspended',
        trialEndDate: trialEndDateStr
      });

      // Si se activa la clínica, activar todos sus usuarios y renovar su fecha de contraseña
      if (nextActive) {
        const usersQuery = query(collection(db, "users"), where("clinicId", "==", clinicId));
        const usersSnap = await getDocs(usersQuery);
        for (const userDoc of usersSnap.docs) {
          await updateDoc(doc(db, "users", userDoc.id), {
            isActive: true,
            lastPasswordChange: new Date().toISOString()
          });
        }
      }
    } catch (err) {
      console.error(err);
    } finally {
      setUpdatingClinicId(null);
    }
  };

  const approveClinicPayment = async (clinicId) => {
    setUpdatingClinicId(clinicId);
    try {
      const hundredYearsFuture = new Date();
      hundredYearsFuture.setFullYear(hundredYearsFuture.getFullYear() + 100);
      const trialEndDateStr = hundredYearsFuture.toISOString();

      await updateDoc(doc(db, "clinics", clinicId), {
        isActive: true,
        isSubscriptionActive: true,
        paymentStatus: 'approved',
        trialEndDate: trialEndDateStr
      });

      // Activar usuarios y renovar contraseña
      const usersQuery = query(collection(db, "users"), where("clinicId", "==", clinicId));
      const usersSnap = await getDocs(usersQuery);
      for (const userDoc of usersSnap.docs) {
        await updateDoc(doc(db, "users", userDoc.id), {
          isActive: true,
          lastPasswordChange: new Date().toISOString()
        });
      }
    } catch (err) {
      console.error(err);
    } finally {
      setUpdatingClinicId(null);
    }
  };

  const t = translations[lang];

  return (
    <>
      {/* ── PANTALLA DE CARGA (Loader Premium) ── */}
      <div className={`page-loader ${loading ? '' : 'fade-out'}`} style={{ display: loading ? 'flex' : 'none' }}>
        <div className="loader-content">
          <div className="loader-logo">
            <img src="/logo.png" alt="FisioApp Logo" />
          </div>
          <div className="loader-spinner"></div>
          <span className="loader-text">{t.loaderText}</span>
        </div>
      </div>

      {currentView === 'superadmin' ? (
        // Super Admin View (Login or Panel)
        <div className="superadmin-wrapper" style={{ minHeight: '100vh', background: '#0f172a', color: '#f8fafc', padding: '24px', fontFamily: 'Inter, sans-serif' }}>
          <style>{`
            .superadmin-container { max-width: 1200px; margin: 0 auto; }
            .superadmin-card { background: rgba(30, 41, 59, 0.7); backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.08); border-radius: 16px; padding: 24px; box-shadow: 0 10px 30px rgba(0,0,0,0.2); }
            .superadmin-title { font-size: 24px; font-weight: 800; color: #10b981; display: flex; align-items: center; gap: 8px; margin-bottom: 24px; }
            .admin-login-card { max-width: 420px; margin: 80px auto; }
            .admin-form-group { margin-bottom: 20px; }
            .admin-form-label { display: block; font-size: 13px; color: #94a3b8; font-weight: 600; margin-bottom: 8px; }
            .admin-form-input { width: 100%; padding: 12px; background: #0f172a; border: 1px solid #334155; border-radius: 8px; color: #f8fafc; font-size: 14px; transition: border 0.2s; }
            .admin-form-input:focus { border-color: #10b981; outline: none; }
            .btn-admin { width: 100%; padding: 12px; background: #10b981; border: none; border-radius: 8px; color: #022c22; font-weight: 700; cursor: pointer; transition: opacity 0.2s; }
            .btn-admin:hover { opacity: 0.9; }
            .btn-admin-secondary { width: 100%; padding: 12px; background: transparent; border: 1px solid #334155; border-radius: 8px; color: #94a3b8; font-weight: 600; cursor: pointer; margin-top: 10px; transition: color 0.2s; }
            .btn-admin-secondary:hover { color: #f8fafc; }
            .admin-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 32px; border-bottom: 1px solid #334155; padding-bottom: 16px; }
            .admin-kpis { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 20px; margin-bottom: 32px; }
            .admin-kpi-card { background: #1e293b; border-radius: 12px; padding: 20px; border-left: 4px solid #10b981; }
            .admin-kpi-val { font-size: 28px; font-weight: 800; color: #f8fafc; margin-top: 8px; }
            .admin-kpi-title { font-size: 12px; color: #94a3b8; font-weight: 600; text-transform: uppercase; }
            .admin-table-container { overflow-x: auto; background: #1e293b; border-radius: 12px; border: 1px solid #334155; }
            .admin-table { width: 100%; border-collapse: collapse; text-align: left; font-size: 14px; }
            .admin-table th { background: #0f172a; padding: 16px; color: #94a3b8; font-weight: 600; font-size: 12px; text-transform: uppercase; border-bottom: 1px solid #334155; }
            .admin-table td { padding: 16px; border-bottom: 1px solid #334155; vertical-align: middle; }
            .admin-table tr:hover { background: rgba(51, 65, 85, 0.3); }
            .badge { display: inline-flex; align-items: center; padding: 4px 10px; font-size: 11px; font-weight: 700; border-radius: 9999px; text-transform: uppercase; }
            .badge-active { background: #065f46; color: #34d399; }
            .badge-inactive { background: #7f1d1d; color: #fca5a5; }
            .badge-pending { background: #78350f; color: #fbbf24; }
            .badge-plan { background: #1e3a8a; color: #93c5fd; }
            .btn-action-sm { padding: 6px 12px; font-size: 12px; font-weight: 700; border-radius: 6px; cursor: pointer; border: none; transition: opacity 0.2s; }
            .btn-approve { background: #10b981; color: #022c22; }
            .btn-toggle-status { background: #3b82f6; color: #fff; }
            .btn-suspend { background: #ef4444; color: #fff; }
            .btn-logout-admin { padding: 8px 16px; background: transparent; border: 1px solid #ef4444; color: #fca5a5; border-radius: 8px; font-weight: 600; cursor: pointer; }
            .btn-logout-admin:hover { background: #ef4444; color: #fff; }
            .search-bar-admin { width: 100%; padding: 12px 16px; border-radius: 8px; background: #1e293b; border: 1px solid #334155; color: #f8fafc; margin-bottom: 20px; font-size: 14px; }
            .search-bar-admin:focus { border-color: #10b981; outline: none; }
          `}</style>
          
          <div className="superadmin-container">
            {!adminLoggedIn ? (
              // Login Card
              <div className="superadmin-card admin-login-card">
                <div className="superadmin-title">🔒 SuperAdmin Login</div>
                <form onSubmit={handleAdminLogin}>
                  {adminError && <div style={{ background: 'rgba(239, 68, 68, 0.15)', color: '#fca5a5', padding: '12px', borderRadius: '8px', fontSize: '13px', marginBottom: '16px', fontWeight: '500' }}>{adminError}</div>}
                  <div className="admin-form-group">
                    <label className="admin-form-label">{lang === 'es' ? 'Contraseña del Propietario' : 'Owner Password'}</label>
                    <input type="password" className="admin-form-input" value={adminPassword} onChange={(e) => setAdminPassword(e.target.value)} placeholder="••••••••" required />
                  </div>
                  <button type="submit" className="btn-admin">{lang === 'es' ? 'Ingresar al Panel' : 'Access Dashboard'}</button>
                  <button type="button" className="btn-admin-secondary" onClick={() => setCurrentView('landing')}>{lang === 'es' ? 'Volver a la Web' : 'Return to Website'}</button>
                </form>
              </div>
            ) : (
              // Admin Panel
              <div className="superadmin-card">
                <div className="admin-header">
                  <div>
                    <h1 style={{ fontSize: '24px', fontWeight: '800', margin: 0 }}>FisioApp</h1>
                    <p style={{ color: '#94a3b8', fontSize: '14px', margin: '4px 0 0 0' }}>Panel de Control del Propietario (Super-Administrador)</p>
                  </div>
                  <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
                    <button className="btn-admin-secondary" style={{ marginTop: 0, padding: '8px 16px' }} onClick={() => setCurrentView('landing')}>{lang === 'es' ? 'Ver Web' : 'View Web'}</button>
                    <button className="btn-logout-admin" onClick={handleAdminLogout}>{lang === 'es' ? 'Cerrar Sesión' : 'Sign Out'}</button>
                  </div>
                </div>

                {/* KPIs */}
                <div className="admin-kpis">
                  <div className="admin-kpi-card" style={{ borderLeftColor: '#10b981' }}>
                    <div className="admin-kpi-title">{lang === 'es' ? 'Clínicas Totales' : 'Total Clinics'}</div>
                    <div className="admin-kpi-val">{clinics.length}</div>
                  </div>
                  <div className="admin-kpi-card" style={{ borderLeftColor: '#3b82f6' }}>
                    <div className="admin-kpi-title">{lang === 'es' ? 'Clínicas Activas' : 'Active Clinics'}</div>
                    <div className="admin-kpi-val">{clinics.filter(c => c.isActive).length}</div>
                  </div>
                  <div className="admin-kpi-card" style={{ borderLeftColor: '#fbbf24' }}>
                    <div className="admin-kpi-title">{lang === 'es' ? 'Pendientes de Pago' : 'Pending Verification'}</div>
                    <div className="admin-kpi-val">{clinics.filter(c => c.paymentStatus === 'pending_verification').length}</div>
                  </div>
                </div>

                {/* Search Bar */}
                <input 
                  type="text" 
                  className="search-bar-admin" 
                  placeholder={lang === 'es' ? "🔍 Buscar clínicas por nombre..." : "🔍 Search clinics by name..."}
                  value={adminSearch}
                  onChange={(e) => setAdminSearch(e.target.value)}
                />

                {/* Table */}
                <div className="admin-table-container">
                  {loadingClinics ? (
                    <div style={{ padding: '40px', textAlign: 'center', color: '#94a3b8' }}>Cargando datos...</div>
                  ) : (
                    <table className="admin-table">
                      <thead>
                        <tr>
                          <th>{lang === 'es' ? 'Clínica' : 'Clinic'}</th>
                          <th>{lang === 'es' ? 'Plan y Ciclo' : 'Plan & Cycle'}</th>
                          <th>{lang === 'es' ? 'Detalles de Pago' : 'Payment Details'}</th>
                          <th>{lang === 'es' ? 'Estado' : 'Status'}</th>
                          <th style={{ textAlign: 'right' }}>{lang === 'es' ? 'Acciones' : 'Actions'}</th>
                        </tr>
                      </thead>
                      <tbody>
                        {clinics.filter(c => c.name?.toLowerCase().includes(adminSearch.toLowerCase())).map(clinic => {
                          const dateStr = clinic.createdAt ? new Date(clinic.createdAt).toLocaleDateString() : 'N/A';
                          return (
                            <tr key={clinic.id}>
                              <td>
                                <strong style={{ color: '#fff', display: 'block' }}>{clinic.name || 'Clínica sin Nombre'}</strong>
                                <span style={{ fontSize: '12px', color: '#94a3b8' }}>ID: {clinic.id} | Creada: {dateStr}</span>
                              </td>
                              <td>
                                <span className="badge badge-plan" style={{ marginRight: '6px' }}>{clinic.selectedPlan || 'Básico'}</span>
                                <span className="badge badge-plan" style={{ background: '#312e81', color: '#c7d2fe' }}>{clinic.billingCycle === 'yearly' ? 'Anual' : 'Mensual'}</span>
                              </td>
                              <td>
                                {clinic.paymentMethod ? (
                                  <div>
                                    <span style={{ fontSize: '13px', fontWeight: '600', color: '#38bdf8', textTransform: 'capitalize' }}>
                                      {clinic.paymentMethod === 'pagomovil' ? 'Pago Móvil' : clinic.paymentMethod === 'binance' ? 'Binance Pay' : 'Transferencia'}
                                    </span>
                                    <div style={{ fontSize: '12px', color: '#94a3b8', marginTop: '2px' }}>
                                      Ref: <strong style={{ color: '#f8fafc' }}>{clinic.paymentReference || 'N/A'}</strong>
                                    </div>
                                  </div>
                                ) : (
                                  <span style={{ color: '#94a3b8', fontSize: '13px' }}>Prueba Gratuita (Trial)</span>
                                )}
                              </td>
                              <td>
                                {clinic.paymentStatus === 'pending_verification' && (
                                  <span className="badge badge-pending" style={{ marginRight: '6px' }}>Espera de Verificación</span>
                                )}
                                {clinic.isActive ? (
                                  <span className="badge badge-active">Activo</span>
                                ) : (
                                  <span className="badge badge-inactive">Suspendido</span>
                                )}
                              </td>
                              <td style={{ textAlign: 'right' }}>
                                <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end' }}>
                                  {clinic.paymentStatus === 'pending_verification' && (
                                    <button 
                                      className="btn-action-sm btn-approve"
                                      disabled={updatingClinicId === clinic.id}
                                      onClick={() => approveClinicPayment(clinic.id)}
                                    >
                                      {updatingClinicId === clinic.id ? 'Aprobando...' : 'Aprobar Pago'}
                                    </button>
                                  )}
                                  <button 
                                    className={`btn-action-sm ${clinic.isActive ? 'btn-suspend' : 'btn-toggle-status'}`}
                                    disabled={updatingClinicId === clinic.id}
                                    onClick={() => toggleClinicActive(clinic.id, clinic.isActive)}
                                  >
                                    {updatingClinicId === clinic.id ? '...' : (clinic.isActive ? 'Suspender' : 'Activar')}
                                  </button>
                                </div>
                              </td>
                            </tr>
                          );
                        })}
                        {clinics.filter(c => c.name?.toLowerCase().includes(adminSearch.toLowerCase())).length === 0 && (
                          <tr>
                            <td colSpan="5" style={{ padding: '30px', textAlign: 'center', color: '#94a3b8' }}>No se encontraron clínicas.</td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  )}
                </div>
              </div>
            )}
          </div>
        </div>
      ) : (
      <>
        {/* ── CABECERA / NAVEGACIÓN ── */}
      <header>
        <div className="logo-container">
          <div className="logo-circle">
            <svg viewBox="0 0 24 24" width="18" height="18" fill="white">
              <path d="M19 10.5h-5.5V5c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v5.5H5c-.83 0-1.5.67-1.5 1.5s.67 1.5 1.5 1.5h5.5V19c0 .83.67 1.5 1.5 1.5s1.5-.67 1.5-1.5v-5.5H19c.83 0 1.5-.67 1.5-1.5s-.67-1.5-1.5-1.5z"/>
            </svg>
          </div>
          <span className="logo-text">FisioApp</span>
        </div>
        <nav>
          <ul className="nav-links">
            <li><a href="#features">{t.navFeatures}</a></li>
            <li><a href="#stats">{t.navStats}</a></li>
            <li><a href="#pricing">{t.navPricing}</a></li>
            <li><a href="#testimonials">{t.navTestimonials}</a></li>
            <li><a href="#faq">{t.navFaq}</a></li>
            <li><a href="#contact">{t.navContact}</a></li>
          </ul>
        </nav>
        <div className="header-controls">
          {/* Selector de Idioma Sliding Pill Switch */}
          <div className="lang-switch-pill">
            <span className={`lang-option ${lang === 'es' ? 'active' : ''}`} onClick={() => handleLanguageSelect('es')}>ES</span>
            <span className={`lang-option ${lang === 'en' ? 'active' : ''}`} onClick={() => handleLanguageSelect('en')}>EN</span>
          </div>
          {/* Theme Switcher */}
          <button className="btn-control" onClick={toggleTheme} title="Cambiar Tema">
            {theme === 'dark' ? '☀️' : '🌙'}
          </button>
          <a href="#pricing" className="btn-cta-nav">{t.btnCtaNav}</a>
        </div>
      </header>

      <main>
        {/* ── HERO SECTION ── */}
        <section className="hero">
          <div className="hero-glow"></div>
          <div className="hero-glow" style={{ top: '50%', left: '80%', background: 'radial-gradient(circle, rgba(15, 118, 110, 0.1) 0%, rgba(0,0,0,0) 60%)' }}></div>
          
          <span className="hero-tagline">{t.heroTagline}</span>
          <h1 dangerouslySetInnerHTML={{ __html: t.heroTitle }}></h1>
          <p>{t.heroSubtitle}</p>
          
          <div className="hero-buttons">
            <a href="#pricing" className="btn-primary">{t.btnHeroCta}</a>
            <a href="#features" className="btn-secondary">{t.btnHeroSecondary}</a>
          </div>

          {/* 3D Clinical Mockup Dashboard */}
          <div className="hero-mockup-container">
            <div className="mockup-header">
              <div className="mockup-dots">
                <span></span><span></span><span></span>
              </div>
              <div className="mockup-search">dashboard.fisioapp.com/clinica-central</div>
            </div>
            <div className="mockup-body">
              <div className="mockup-sidebar">
                <div className={`sidebar-item ${activeTab === 'dashboard' ? 'active' : ''}`} onClick={() => setActiveTab('dashboard')}>{t.mockupSidebarDashboard}</div>
                <div className={`sidebar-item ${activeTab === 'agenda' ? 'active' : ''}`} onClick={() => setActiveTab('agenda')}>{t.mockupSidebarAgenda}</div>
                <div className={`sidebar-item ${activeTab === 'pacientes' ? 'active' : ''}`} onClick={() => setActiveTab('pacientes')}>{t.mockupSidebarPacientes}</div>
                <div className={`sidebar-item ${activeTab === 'cobranza' ? 'active' : ''}`} onClick={() => setActiveTab('cobranza')}>{t.mockupSidebarCobranza}</div>
                <div className={`sidebar-item ${activeTab === 'configuracion' ? 'active' : ''}`} onClick={() => setActiveTab('configuracion')}>{t.mockupSidebarConfig}</div>
              </div>
              <div className="mockup-content">
                {/* Dashboard Tab */}
                {activeTab === 'dashboard' && (
                  <div className="mockup-tab-content active">
                    <div className="mockup-grid">
                      <div className="mockup-card">
                        <h4>{t.mockupKpiRevenue}</h4>
                        <div className="mockup-value">$8,450.00</div>
                        <div className="mockup-trend text-green">{t.mockupKpiRevenueTrend}</div>
                      </div>
                      <div className="mockup-card">
                        <h4>{t.mockupKpiPatients}</h4>
                        <div className="mockup-value">342</div>
                        <div className="mockup-trend text-green">{t.mockupKpiPatientsTrend}</div>
                      </div>
                      <div className="mockup-card">
                        <h4>{t.mockupKpiSessions}</h4>
                        <div className="mockup-value">186</div>
                        <div className="mockup-trend text-orange">{t.mockupKpiSessionsTrend}</div>
                      </div>
                    </div>
                    <div className="mockup-chart-placeholder">
                      <div className="chart-header">{t.mockupChartHeader}</div>
                      <div className="chart-bars">
                        <div className="bar" style={{ height: '40%' }}><span>{t.dayMon}</span></div>
                        <div className="bar" style={{ height: '65%' }}><span>{t.dayTue}</span></div>
                        <div className="bar" style={{ height: '50%' }}><span>{t.dayWed}</span></div>
                        <div className="bar" style={{ height: '85%' }}><span>{t.dayThu}</span></div>
                        <div className="bar active" style={{ height: '95%' }}><span>{t.dayFri}</span></div>
                        <div className="bar" style={{ height: '30%' }}><span>{t.daySat}</span></div>
                      </div>
                    </div>
                  </div>
                )}

                {/* Agenda Tab */}
                {activeTab === 'agenda' && (
                  <div className="mockup-tab-content active">
                    <div className="mockup-agenda-header">
                      <strong>{t.mockupAgendaHeaderTitle}</strong>
                      <span className="badge-active">{t.mockupAgendaToday}</span>
                    </div>
                    <div className="mockup-agenda-list">
                      <div className="agenda-row">
                        <span className="time">09:00 AM</span>
                        <div className="appointment-card border-green">
                          <strong>Carlos Pérez</strong>
                          <span>{t.mockupAgendaCard1}</span>
                        </div>
                      </div>
                      <div className="agenda-row">
                        <span className="time">10:30 AM</span>
                        <div className="appointment-card border-blue">
                          <strong>Ana Gómez</strong>
                          <span>{t.mockupAgendaCard2}</span>
                        </div>
                      </div>
                      <div className="agenda-row">
                        <span className="time">12:00 PM</span>
                        <div className="appointment-card border-purple">
                          <strong>Luis Rodríguez</strong>
                          <span>{t.mockupAgendaCard3}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                )}

                {/* Patients Tab */}
                {activeTab === 'pacientes' && (
                  <div className="mockup-tab-content active">
                    <div className="mockup-search-bar">
                      <input type="text" disabled placeholder={t.mockupSearchPlaceholder} />
                    </div>
                    <div className="mockup-patient-list">
                      <div className="patient-item">
                        <div className="patient-info">
                          <strong>María del Carmen</strong>
                          <span>DNI: 34.920.123 • Tel: 654 321 098</span>
                        </div>
                        <div className="patient-badges">
                          <span className="badge badge-green">{t.mockupPatientBadge1}</span>
                          <span className="badge badge-purple">{t.mockupPatientBadge2}</span>
                        </div>
                      </div>
                      <div className="patient-item">
                        <div className="patient-info">
                          <strong>Roberto Gómez</strong>
                          <span>DNI: 21.045.789 • Tel: 612 345 678</span>
                        </div>
                        <div className="patient-badges">
                          <span className="badge badge-green">{t.mockupPatientBadge1}</span>
                          <span className="badge badge-orange">{t.mockupPatientBadge3}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                )}

                {/* Billing Tab */}
                {activeTab === 'cobranza' && (
                  <div className="mockup-tab-content active">
                    <div className="mockup-grid">
                      <div className="mockup-card">
                        <h4>{t.mockupKpiDaily}</h4>
                        <div className="mockup-value">$340.00</div>
                        <div className="mockup-trend text-green">{t.mockupKpiDailyTrend}</div>
                      </div>
                      <div className="mockup-card">
                        <h4>{t.mockupKpiDebts}</h4>
                        <div className="mockup-value">$80.00</div>
                        <div className="mockup-trend text-orange">{t.mockupKpiDebtsTrend}</div>
                      </div>
                      <div className="mockup-card">
                        <h4>{t.mockupKpiPacks}</h4>
                        <div className="mockup-value">12</div>
                        <div className="mockup-trend text-green">{t.mockupKpiPacksTrend}</div>
                      </div>
                    </div>
                    <div className="mockup-payments-list">
                      <div className="payment-item-row">
                        <span>{t.mockupPayRow1}</span>
                        <strong className="text-green">+$40.00 (Efectivo)</strong>
                      </div>
                      <div className="payment-item-row">
                        <span>{t.mockupPayRow2}</span>
                        <strong className="text-green">+$300.00 (Tarjeta)</strong>
                      </div>
                    </div>
                  </div>
                )}

                {/* Settings Tab */}
                {activeTab === 'configuracion' && (
                  <div className="mockup-tab-content active">
                    <div className="mockup-settings-list">
                      <div className="settings-row">
                        <div className="settings-text">
                          <strong>{t.mockupSetBiometricsTitle}</strong>
                          <span>{t.mockupSetBiometricsDesc}</span>
                        </div>
                        <div className="settings-switch active"><span></span></div>
                      </div>
                      <div className="settings-row">
                        <div className="settings-text">
                          <strong>{t.mockupSetPushTitle}</strong>
                          <span>{t.mockupSetPushDesc}</span>
                        </div>
                        <div className="settings-switch active"><span></span></div>
                      </div>
                      <div className="settings-row">
                        <div className="settings-text">
                          <strong>{t.mockupSetLangTitle}</strong>
                          <span>{t.mockupSetLangDesc}</span>
                        </div>
                        <div className="settings-select">{lang === 'es' ? 'Español' : 'English'}</div>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </section>

        {/* ── FEATURES SECTION ── */}
        <section className="features" id="features">
          <h2 className="section-title">{t.featuresTitle}</h2>
          <p className="section-subtitle">{t.featuresSubtitle}</p>
          
          <div className="features-grid">
            {/* Agenda */}
            <div className={`feature-card ${expandedFeatures.agenda ? 'active' : ''}`}>
              <div className="feature-icon-wrapper">📅</div>
              <h3>{t.featCardTitle1}</h3>
              <p className="feature-short">{t.featCardDesc1}</p>
              <div className="feature-detail">
                <ul>
                  <li>{t.featCard1Bullet1}</li>
                  <li>{t.featCard1Bullet2}</li>
                  <li>{t.featCard1Bullet3}</li>
                  <li>{t.featCard1Bullet4}</li>
                </ul>
              </div>
              <span className="feature-toggle-btn" onClick={() => toggleFeature('agenda')}>
                {expandedFeatures.agenda ? t.closeDetails : t.viewDetails}
              </span>
            </div>

            {/* SOAP Records */}
            <div className={`feature-card ${expandedFeatures.expediente ? 'active' : ''}`}>
              <div className="feature-icon-wrapper">📝</div>
              <h3>{t.featCardTitle2}</h3>
              <p className="feature-short">{t.featCardDesc2}</p>
              <div className="feature-detail">
                <ul>
                  <li>{t.featCard2Bullet1}</li>
                  <li>{t.featCard2Bullet2}</li>
                  <li>{t.featCard2Bullet3}</li>
                  <li>{t.featCard2Bullet4}</li>
                </ul>
              </div>
              <span className="feature-toggle-btn" onClick={() => toggleFeature('expediente')}>
                {expandedFeatures.expediente ? t.closeDetails : t.viewDetails}
              </span>
            </div>

            {/* Digital Signature */}
            <div className={`feature-card ${expandedFeatures.firma ? 'active' : ''}`}>
              <div className="feature-icon-wrapper">✍️</div>
              <h3>{t.featCardTitle3}</h3>
              <p className="feature-short">{t.featCardDesc3}</p>
              <div className="feature-detail">
                <ul>
                  <li>{t.featCard3Bullet1}</li>
                  <li>{t.featCard3Bullet2}</li>
                  <li>{t.featCard3Bullet3}</li>
                  <li>{t.featCard3Bullet4}</li>
                </ul>
              </div>
              <span className="feature-toggle-btn" onClick={() => toggleFeature('firma')}>
                {expandedFeatures.firma ? t.closeDetails : t.viewDetails}
              </span>
            </div>

            {/* Billing Ledger */}
            <div className={`feature-card ${expandedFeatures.cobranza ? 'active' : ''}`}>
              <div className="feature-icon-wrapper">💳</div>
              <h3>{t.featCardTitle4}</h3>
              <p className="feature-short">{t.featCardDesc4}</p>
              <div className="feature-detail">
                <ul>
                  <li>{t.featCard4Bullet1}</li>
                  <li>{t.featCard4Bullet2}</li>
                  <li>{t.featCard4Bullet3}</li>
                  <li>{t.featCard4Bullet4}</li>
                </ul>
              </div>
              <span className="feature-toggle-btn" onClick={() => toggleFeature('cobranza')}>
                {expandedFeatures.cobranza ? t.closeDetails : t.viewDetails}
              </span>
            </div>

            {/* Performance Reports */}
            <div className={`feature-card ${expandedFeatures.reportes ? 'active' : ''}`}>
              <div className="feature-icon-wrapper">📊</div>
              <h3>{t.featCardTitle5}</h3>
              <p className="feature-short">{t.featCardDesc5}</p>
              <div className="feature-detail">
                <ul>
                  <li>{t.featCard5Bullet1}</li>
                  <li>{t.featCard5Bullet2}</li>
                  <li>{t.featCard5Bullet3}</li>
                  <li>{t.featCard5Bullet4}</li>
                </ul>
              </div>
              <span className="feature-toggle-btn" onClick={() => toggleFeature('reportes')}>
                {expandedFeatures.reportes ? t.closeDetails : t.viewDetails}
              </span>
            </div>

            {/* Patient Portal */}
            <div className={`feature-card ${expandedFeatures.portal ? 'active' : ''}`}>
              <div className="feature-icon-wrapper">🔔</div>
              <h3>{t.featCardTitle6}</h3>
              <p className="feature-short">{t.featCardDesc6}</p>
              <div className="feature-detail">
                <ul>
                  <li>{t.featCard6Bullet1}</li>
                  <li>{t.featCard6Bullet2}</li>
                  <li>{t.featCard6Bullet3}</li>
                  <li>{t.featCard6Bullet4}</li>
                </ul>
              </div>
              <span className="feature-toggle-btn" onClick={() => toggleFeature('portal')}>
                {expandedFeatures.portal ? t.closeDetails : t.viewDetails}
              </span>
            </div>
          </div>
        </section>

        {/* ── STATS SECTION ── */}
        <section className="stats-section" id="stats">
          <div className="stats-grid">
            <div className="stat-item">
              <div className="stat-number">+10,000</div>
              <div className="stat-label">{t.statLabel1}</div>
            </div>
            <div className="stat-item">
              <div className="stat-number">99.98%</div>
              <div className="stat-label">{t.statLabel2}</div>
            </div>
            <div className="stat-item">
              <div className="stat-number">{t.statNumber3}</div>
              <div className="stat-label">{t.statLabel3}</div>
            </div>
            <div className="stat-item">
              <div className="stat-number">4.9 / 5</div>
              <div className="stat-label">{t.statLabel4}</div>
            </div>
          </div>
        </section>

        {/* ── PRICING SECTION ── */}
        <section className="pricing" id="pricing">
          <h2 className="section-title">{t.pricingTitle}</h2>
          <p className="section-subtitle">{t.pricingSubtitle}</p>

          {/* Selector de Ciclo Mensual/Anual */}
          <div className="pricing-toggle-container" style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '16px', marginBottom: '50px' }}>
            <span style={{ fontSize: '14px', fontWeight: '700', color: billingCycle === 'monthly' ? 'var(--text-white)' : 'var(--text-gray)', cursor: 'pointer' }} onClick={() => setBillingCycle('monthly')}>
              {lang === 'es' ? 'Mensual' : 'Monthly'}
            </span>
            <div 
              onClick={() => setBillingCycle(prev => prev === 'monthly' ? 'yearly' : 'monthly')} 
              style={{ position: 'relative', width: '56px', height: '28px', borderRadius: '14px', background: 'var(--gradient-brand)', cursor: 'pointer', transition: 'background 0.3s' }}
            >
              <span style={{ position: 'absolute', top: '4px', left: billingCycle === 'monthly' ? '4px' : '32px', width: '20px', height: '20px', borderRadius: '50%', background: 'white', transition: 'left 0.2s ease-in-out' }}></span>
            </div>
            <span style={{ fontSize: '14px', fontWeight: '700', color: billingCycle === 'yearly' ? 'var(--text-white)' : 'var(--text-gray)', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px' }} onClick={() => setBillingCycle('yearly')}>
              {lang === 'es' ? 'Anual' : 'Yearly'}
              <span style={{ background: 'var(--primary-light)', color: '#0A0F1D', padding: '2px 8px', borderRadius: '20px', fontSize: '10px', fontWeight: '800' }}>
                {lang === 'es' ? 'Ahorra 20%' : 'Save 20%'}
              </span>
            </span>
          </div>

          <div className="pricing-grid">
            {/* Basic Plan */}
            <div className="price-card" id="cardPlanBasico">
              <h3>{t.plan1Title}</h3>
              <p className="desc">{t.plan1Desc}</p>
              <div className="price-value">
                ${billingCycle === 'monthly' ? '19' : '15'} 
                <span style={{ fontSize: '12px', marginLeft: '6px' }}>
                  {billingCycle === 'monthly' ? t.pricePeriod : (lang === 'es' ? '/ mes (cobrado anual)' : '/ month (billed yearly)')}
                </span>
              </div>
              <ul className="price-features">
                <li>{t.plan1Feature1}</li>
                <li>{t.plan1Feature2}</li>
                <li>{t.plan1Feature3}</li>
                <li>{t.plan1Feature4}</li>
                <li>{t.plan1Feature5}</li>
              </ul>
              <button className="btn-plan select-plan-btn" onClick={() => openRegisterModal('Plan Básico')}>{t.btnPlan1}</button>
            </div>

            {/* Professional Plan (Featured) */}
            <div className="price-card featured" id="cardPlanProfesional">
              <div className="badge-featured">{t.badgeFeatured}</div>
              <h3>{t.plan2Title}</h3>
              <p className="desc">{t.plan2Desc}</p>
              <div className="price-value">
                ${billingCycle === 'monthly' ? '39' : '31'} 
                <span style={{ fontSize: '12px', marginLeft: '6px' }}>
                  {billingCycle === 'monthly' ? t.pricePeriod : (lang === 'es' ? '/ mes (cobrado anual)' : '/ month (billed yearly)')}
                </span>
              </div>
              <ul className="price-features">
                <li>{t.plan2Feature1}</li>
                <li>{t.plan2Feature2}</li>
                <li>{t.plan2Feature3}</li>
                <li>{t.plan2Feature4}</li>
                <li>{t.plan2Feature5}</li>
                <li>{t.plan2Feature6}</li>
              </ul>
              <button className="btn-plan select-plan-btn" onClick={() => openRegisterModal('Plan Profesional')}>{t.btnPlan2}</button>
            </div>

            {/* Enterprise Plan */}
            <div className="price-card" id="cardPlanEnterprise">
              <h3>{t.plan3Title}</h3>
              <p className="desc">{t.plan3Desc}</p>
              <div className="price-value">
                ${billingCycle === 'monthly' ? '79' : '63'} 
                <span style={{ fontSize: '12px', marginLeft: '6px' }}>
                  {billingCycle === 'monthly' ? t.pricePeriod : (lang === 'es' ? '/ mes (cobrado anual)' : '/ month (billed yearly)')}
                </span>
              </div>
              <ul className="price-features">
                <li>{t.plan3Feature1}</li>
                <li>{t.plan3Feature2}</li>
                <li>{t.plan3Feature3}</li>
                <li>{t.plan3Feature4}</li>
                <li>{t.plan3Feature5}</li>
                <li>{t.plan3Feature6}</li>
              </ul>
              <button className="btn-plan select-plan-btn" onClick={() => openRegisterModal('Plan Enterprise')}>{t.btnPlan3}</button>
            </div>
          </div>
        </section>

        {/* ── TESTIMONIALS SECTION ── */}
        <section className="testimonials" id="testimonials">
          <h2 className="section-title">{t.testimonialsTitle}</h2>
          <p className="section-subtitle">{t.testimonialsSubtitle}</p>
          
          <div className="testimonials-grid">
            <div className="testimonial-card">
              <div className="testimonial-rating">★★★★★</div>
              <p>{t.review1Text}</p>
              <div className="testimonial-author">
                <div className="author-avatar" style={{ backgroundImage: "url('https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=100&q=80')" }}></div>
                <div>
                  <strong>Dra. Sofía Galindo</strong>
                  <span>{t.review1Role}</span>
                </div>
              </div>
            </div>
            <div className="testimonial-card">
              <div className="testimonial-rating">★★★★★</div>
              <p>{t.review2Text}</p>
              <div className="testimonial-author">
                <div className="author-avatar" style={{ backgroundImage: "url('https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=100&q=80')" }}></div>
                <div>
                  <strong>Lic. Marcos Ruiz</strong>
                  <span>{t.review2Role}</span>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ── FAQ SECTION ── */}
        <section className="faq-section" id="faq">
          <h2 className="section-title">{t.faqTitle}</h2>
          <p className="section-subtitle">{t.faqSubtitle}</p>

          <div className="faq-container">
            {[0, 1, 2, 3].map((idx) => {
              const qKey = `faqQ${idx + 1}`;
              const aKey = `faqA${idx + 1}`;
              return (
                <div className={`faq-item ${activeFaq[idx] ? 'active' : ''}`} key={idx}>
                  <button className="faq-question" onClick={() => toggleFaqItem(idx)}>
                    <span>{t[qKey]}</span>
                    <span>{activeFaq[idx] ? '−' : '+'}</span>
                  </button>
                  <div className="faq-answer">
                    <p>{t[aKey]}</p>
                  </div>
                </div>
              );
            })}
          </div>
        </section>

        {/* ── CONTACT SECTION ── */}
        <section className="contact" id="contact">
          <h2 className="section-title">{t.contactTitle}</h2>
          <p className="section-subtitle">{t.contactSubtitle}</p>
          
          <div className="contact-container">
            {/* Direct Link Panel */}
            <div className="contact-info-panel">
              <div className="info-card">
                <div className="info-icon">✉️</div>
                <div>
                  <h4>{t.contactInfoEmail}</h4>
                  <p>{t.contactInfoEmailDesc}</p>
                  <a href="mailto:soporte@fisioapp.com" className="link-email">soporte@fisioapp.com</a>
                </div>
              </div>
            </div>

            {/* Leads Form Panel */}
            <div className="contact-form-panel">
              <form onSubmit={handleLeadSubmit}>
                <div className="form-group">
                  <label>{t.contactLabelName}</label>
                  <input type="text" required placeholder={t.phAdminName} value={leadName} onChange={(e) => setLeadName(e.target.value)} />
                </div>
                <div className="form-group">
                  <label>{t.labelEmail}</label>
                  <input type="email" required placeholder={t.phEmail} value={leadEmail} onChange={(e) => setLeadEmail(e.target.value)} />
                </div>
                <div className="form-group">
                  <label>{t.contactLabelMsg}</label>
                  <textarea rows="4" required placeholder={t.phLeadMsg} value={leadMessage} onChange={(e) => setLeadMessage(e.target.value)} style={{ width:'100%', padding:'14px 16px', borderRadius:'12px', background:'rgba(255,255,255,0.03)', border:'1px solid var(--border-light)', color:'var(--text-white)', fontSize:'14px', outline:'none', transition:'border-color 0.3s', resize:'none' }}></textarea>
                </div>
                {leadFeedback && <div className="feedback info">{leadFeedback}</div>}
                <button type="submit" className="btn-submit" disabled={isLeadSubmitting}>
                  {isLeadSubmitting ? (lang === 'es' ? 'Enviando...' : 'Sending...') : t.btnSendMessage}
                </button>
              </form>
            </div>
          </div>
        </section>
      </main>

      {/* ── FOOTER ── */}
      <footer>
        <p>{t.footerText}</p>
      </footer>

      {/* ── MODAL DE REGISTRO (FORMULARIO SAAS) ── */}
      {modalOpen && (
        <div className="modal-overlay active">
          <div className="modal-content" style={{ maxWidth: '520px' }}>
            <button className="modal-close" onClick={() => setModalOpen(false)}>&times;</button>
            
            {/* Indicador de pasos */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px', borderBottom: '1px solid var(--border-light)', paddingBottom: '12px' }}>
              <h2 style={{ fontSize: '18px', margin: 0 }}>{t.modalTitle} ({selectedPlan})</h2>
              <span style={{ fontSize: '12px', fontWeight: 'bold', background: 'var(--primary-glow)', color: 'var(--primary-light)', padding: '4px 10px', borderRadius: '20px' }}>
                {lang === 'es' ? `Paso ${regStep} de 2` : `Step ${regStep} of 2`}
              </span>
            </div>

            <form id="registerForm" onSubmit={handleRegisterSubmit}>
              {/* Paso 1: Datos de Registro */}
              <div style={{ display: regStep === 1 ? 'block' : 'none' }}>
                <p className="subtitle" style={{ marginBottom: '20px' }}>{t.modalSubtitle}</p>
                
                {/* Info de Clínica */}
                <div className="form-group">
                  <label>{t.labelClinicName}</label>
                  <input type="text" name="clinicName" required={regStep === 1} placeholder={t.phClinicName} />
                </div>

                {/* Info del Administrador */}
                <div className="form-group">
                  <label>{t.labelAdminName}</label>
                  <input type="text" name="adminName" required={regStep === 1} placeholder={t.phAdminName} />
                </div>

                <div className="form-group">
                  <label>{t.labelUsername}</label>
                  <input type="text" name="username" required={regStep === 1} placeholder={t.phUsername} autoComplete="username" />
                </div>

                <div className="form-group">
                  <label>{t.labelEmail}</label>
                  <input type="email" name="email" required={regStep === 1} placeholder={t.phEmail} autoComplete="email" />
                </div>

                <div className="form-group">
                  <label>{t.labelPassword}</label>
                  <input type="password" name="password" required={regStep === 1} placeholder="••••••••" autoComplete="new-password" />
                </div>

                {/* Preguntas de Seguridad */}
                <div className="form-group">
                  <label>{t.labelSecurityQ}</label>
                  <select name="securityQuestion" required={regStep === 1} defaultValue="">
                    <option value="" disabled>{t.optSelectQ}</option>
                    <option value="¿Cuál es tu color favorito?">{t.optQ1}</option>
                    <option value="¿Cuál es el nombre de tu primera mascota?">{t.optQ2}</option>
                    <option value="¿En qué ciudad naciste?">{t.optQ3}</option>
                    <option value="¿Cuál es tu comida favorita?">{t.optQ4}</option>
                  </select>
                </div>

                <div className="form-group">
                  <label>{t.labelSecurityA}</label>
                  <input type="text" name="securityAnswer" required={regStep === 1} placeholder={t.phSecurityA} />
                </div>

                <button 
                  type="button" 
                  className="btn-submit" 
                  style={{ marginTop: '10px' }}
                  onClick={() => {
                    const form = document.getElementById('registerForm');
                    if (form.checkValidity()) {
                      setRegStep(2);
                    } else {
                      form.reportValidity();
                    }
                  }}
                >
                  {lang === 'es' ? 'Siguiente: Detalles de Pago ➔' : 'Next: Payment Details ➔'}
                </button>
              </div>

              {/* Paso 2: Activación y Promoción Gratis */}
              <div style={{ display: regStep === 2 ? 'block' : 'none' }}>
                {/* Detalles del Plan Seleccionado */}
                <div style={{ background: 'rgba(255,255,255,0.02)', padding: '16px', borderRadius: '12px', border: '1px solid var(--border-light)', marginBottom: '24px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                    <span style={{ fontSize: '13px', color: 'var(--text-gray)' }}>{lang === 'es' ? 'Plan Elegido:' : 'Selected Plan:'}</span>
                    <strong style={{ fontSize: '13px' }}>{selectedPlan}</strong>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                    <span style={{ fontSize: '13px', color: 'var(--text-gray)' }}>{lang === 'es' ? 'Ciclo de Cobro:' : 'Billing Cycle:'}</span>
                    <strong style={{ fontSize: '13px' }}>{billingCycle === 'monthly' ? (lang === 'es' ? 'Mensual' : 'Monthly') : (lang === 'es' ? 'Anual' : 'Yearly')}</strong>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', paddingTop: '8px', borderTop: '1px dashed var(--border-light)' }}>
                    <span style={{ fontSize: '14px', fontWeight: 'bold' }}>{lang === 'es' ? 'Total a Pagar:' : 'Total Amount:'}</span>
                    <strong style={{ fontSize: '14px', color: '#10B981' }}>
                      {lang === 'es' ? 'Gratis (Acceso de Prueba)' : 'Free (Trial Access)'}
                    </strong>
                  </div>
                </div>

                <div style={{ padding: '16px', borderRadius: '12px', background: 'rgba(16, 185, 129, 0.05)', border: '1px solid rgba(16, 185, 129, 0.2)', marginBottom: '20px', fontSize: '13px', lineHeight: '1.6', color: '#34d399' }}>
                  <strong>{lang === 'es' ? '¡Promoción de Lanzamiento Activa!' : 'Launch Promotion Active!'}</strong><br />
                  {lang === 'es' ? 
                    'Estamos en fase de prueba y demostración. Tu clínica será creada y activada de forma inmediata sin costo alguno.' : 
                    'We are currently in demo and trial mode. Your clinic will be created and activated immediately at zero cost.'}
                </div>

                {formError && <div className="feedback error" style={{ marginBottom: '15px' }}>{formError}</div>}

                <div style={{ display: 'flex', gap: '12px', marginTop: '20px' }}>
                  <button type="button" className="btn-secondary" onClick={() => setRegStep(1)} style={{ width: '35%', padding: '14px 0' }}>
                    {lang === 'es' ? '◀ Atrás' : '◀ Back'}
                  </button>
                  <button type="submit" className="btn-submit" disabled={isSubmitting} style={{ flexGrow: 1 }}>
                    {isSubmitting ? (lang === 'es' ? 'Activando...' : 'Activating...') : (lang === 'es' ? 'Activar Clínica ✓' : 'Activate Clinic ✓')}
                  </button>
                </div>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ── CARD DE ÉXITO AL REGISTRAR ── */}
      {successOpen && (
        <div className="success-card active" style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'rgba(15, 23, 42, 0.9)', backdropFilter: 'blur(10px)' }}>
          <div className="success-content" style={{ maxWidth: '500px', width: '90%', margin: '0 auto' }}>
            <div className="success-icon" style={{ cursor: 'pointer' }} onClick={() => setSuccessOpen(false)}>✓</div>
            <h2>{t.successTitle}</h2>
            <p className="success-intro">
              <span>{t.successIntroPart1}</span> <strong>{registeredClinic}</strong> <span>{t.successIntroPart2}</span>
            </p>
            
            <div className="credentials-box" style={{ textAlign: 'center' }}>
              <h4 style={{ marginBottom: '8px' }}>{t.successCredsSentTitle}</h4>
              <p style={{ fontSize: '13px', color: 'var(--text-gray)', lineHeight: '1.5' }}>
                {lang === 'es' ? 'Hemos enviado un correo a ' : 'We have sent an email to '}
                <strong>{registeredEmail}</strong>
                {lang === 'es' ? ' con tu nombre de usuario, contraseña temporal y las instrucciones para iniciar sesión.' : ' containing your login username, temporary password, and instructions.'}
              </p>
            </div>

            <div className="download-app-section" style={{ marginTop: '24px' }}>
              <h3>{t.successDownloadTitle}</h3>
              <p>{t.successDownloadDesc}</p>
              <a href="https://firebasestorage.googleapis.com/v1/b/fisioapp-df863.firebasestorage.app/o/fisioapp.apk?alt=media" download className="btn-apk-download">
                <svg viewBox="0 0 24 24">
                  <path d="M17.5 12c-.83 0-1.5-.67-1.5-1.5S16.67 9 17.5 9s1.5.67 1.5 1.5-.67 1.5-1.5 1.5zm-11 0c-.83 0-1.5-.67-1.5-1.5S5.67 9 6.5 9s1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8 0-.58.07-1.15.2-1.7h15.6c.13.55.2 1.12.2 1.7 0 4.41-3.59 8-8 8zm0-11c-2.48 0-4.5 2.02-4.5 4.5S9.52 18 12 18s4.5-2.02 4.5-4.5S14.48 9 12 9zm0 7c-1.38 0-2.5-1.12-2.5-2.5S10.62 11 12 11s2.5 1.12 2.5 2.5S13.38 16 12 16z"/>
                </svg>
                <span>{t.btnDownloadApk}</span>
              </a>
            </div>
            
            <button className="btn-secondary" onClick={() => setSuccessOpen(false)} style={{ marginTop: '20px', width: '100%' }}>
              {lang === 'es' ? 'Cerrar ventana' : 'Close window'}
            </button>
          </div>
        </div>
      )}

      </>
      )}

      {/* ── BOTÓN FLOTANTE DE WHATSAPP ── */}
      <a href="https://wa.me/584125365425?text=Hola!%20Deseo%20más%20información%20sobre%20FisioApp" className="whatsapp-float" target="_blank" rel="noopener noreferrer" aria-label="Contacto por WhatsApp">
        <svg viewBox="0 0 24 24">
          <path d="M12.004 2C6.51 2 2.014 6.5 2.014 12c0 2.14.67 4.12 1.83 5.75L2 22l4.42-1.8c1.62.9 3.49 1.41 5.58 1.41 5.49 0 9.99-4.5 9.99-10S17.5 2 12.004 2zm5.72 13.9c-.24.68-1.21 1.25-1.68 1.33-.42.07-.96.11-2.91-.68-2.5-1.02-4.1-3.6-4.22-3.77-.12-.17-1.02-1.39-1.02-2.65 0-1.26.64-1.88.88-2.13.24-.25.5-.32.67-.32h.48c.17 0 .39-.01.59.48.21.5.73 1.84.8 1.97.07.13.11.29.02.48-.09.18-.18.31-.35.5-.18.19-.38.43-.54.58-.18.17-.37.36-.16.73.21.36.94 1.57 2.01 2.53 1.38 1.23 2.54 1.62 2.91 1.8.36.18.58.15.8-.09.21-.24.94-1.11 1.19-1.48.25-.37.5-.31.84-.18.34.13 2.18 1.05 2.55 1.24.37.19.62.29.7.43.09.15.09.84-.15 1.52z"/>
        </svg>
      </a>
    </>
  );
}
