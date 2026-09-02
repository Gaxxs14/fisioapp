import '../../domain/entities/orthopedic_test.dart';

class OrthopedicTestsRepository {
  static final List<OrthopedicTest> allTests = [
    // ─── HOMBRO ─────────────────────────────────────────────────────────────
    const OrthopedicTest(
      id: 'hombro-neer',
      name: 'Test de Neer',
      region: JointRegion.shoulder,
      targetStructure: 'Conflicto / Atrapamiento subacromial (Manguito rotador y bursa)',
      patientPosition: 'Sedente o bipedestación con el brazo relajado.',
      examinerAction: 'El examinador fija la escápula con una mano para evitar su rotación y con la otra realiza una elevación/flexión anterior pasiva forzada del brazo en rotación interna.',
      positiveFinding: 'Aparición o reproducción del dolor subacromial familiar del paciente, habitualmente entre los 90° y 120° de flexión.',
      clinicalInterpretation: 'Sugiere impingement subacromial, tendinopatía del supraespinoso o bursitis subacromiodeltoidea.',
      sensitivity: '79% - 88%',
      specificity: '53% - 60%',
      tags: ['hombro', 'impingement', 'supraespinoso', 'manguito rotador', 'bursa'],
    ),
    const OrthopedicTest(
      id: 'hombro-hawkins',
      name: 'Test de Hawkins-Kennedy',
      region: JointRegion.shoulder,
      targetStructure: 'Espacio subacromial y tendón del supraespinoso / ligamento coracoacromial',
      patientPosition: 'Sedente con hombro en 90° de flexión y codo flexionado a 90°.',
      examinerAction: 'El terapeuta sostiene el codo del paciente y aplica una rotación interna forzada y rápida del húmero hacia abajo.',
      positiveFinding: 'Dolor punzante o doloroso en la cara anterolateral del hombro durante la rotación interna.',
      clinicalInterpretation: 'Conflicto subacromial por compresión del manguito contra el arco coracoacromial.',
      sensitivity: '80% - 92%',
      specificity: '56% - 65%',
      tags: ['hombro', 'hawkins', 'impingement', 'rotadores'],
    ),
    const OrthopedicTest(
      id: 'hombro-jobe',
      name: 'Test de Jobe (Empty Can)',
      region: JointRegion.shoulder,
      targetStructure: 'Tendón del músculo Supraespinoso',
      patientPosition: 'Bipedestación con ambos brazos en 90° de abducción en plano escapular (30° anterior) y rotación interna completa (pulgares hacia abajo).',
      examinerAction: 'El examinador aplica una fuerza descendente en los antebrazos mientras el paciente intenta resistir.',
      positiveFinding: 'Debilidad motora evidente, incapacidad para resistir la fuerza o dolor agudo localizado en el supraespinoso.',
      clinicalInterpretation: 'Indica tendinopatía severa o rotura parcial/completa del tendón del supraespinoso.',
      sensitivity: '84% - 89%',
      specificity: '68% - 75%',
      tags: ['hombro', 'jobe', 'supraespinoso', 'fuerza', 'rotura'],
    ),
    const OrthopedicTest(
      id: 'hombro-speed',
      name: 'Test de Speed (Palm-Up Test)',
      region: JointRegion.shoulder,
      targetStructure: 'Tendón de la porción larga del bíceps braquial y labrum anterior',
      patientPosition: 'Sedente o de pie, con codo en extensión completa y antebrazo en supinación (palma hacia arriba).',
      examinerAction: 'El paciente flexiona el hombro contra la resistencia manual aplicada por el examinador en la muñeca.',
      positiveFinding: 'Dolor en la corredera bicipital o en la región anterior de la articulación glenohumeral.',
      clinicalInterpretation: 'Tendinopatía bicipital o lesión labral tipo SLAP.',
      sensitivity: '63% - 72%',
      specificity: '67% - 81%',
      tags: ['hombro', 'biceps', 'corredera', 'speed', 'slap'],
    ),

    // ─── RODILLA ────────────────────────────────────────────────────────────
    const OrthopedicTest(
      id: 'rodilla-lachman',
      name: 'Test de Lachman',
      region: JointRegion.knee,
      targetStructure: 'Ligamento Cruzado Anterior (LCA)',
      patientPosition: 'Decúbito supino con rodilla en flexión de 20° a 30° y musculatura relajada.',
      examinerAction: 'Una mano estabiliza el fémur distal por la cara anterior; la otra mano abraza la tibia proximal por la cara posterior y realiza una traslación anterior firme y rápida.',
      positiveFinding: 'Desplazamiento anterior aumentado de la tibia respecto al fémur y/o sensación de tope blando/esponjoso sin límite firme.',
      clinicalInterpretation: 'Es la prueba clínica más sensible y fiable para diagnosticar una rotura del LCA.',
      sensitivity: '85% - 95%',
      specificity: '94% - 98%',
      tags: ['rodilla', 'lca', 'cruzados', 'lachman', 'ligamento'],
    ),
    const OrthopedicTest(
      id: 'rodilla-mcmurray',
      name: 'Test de McMurray',
      region: JointRegion.knee,
      targetStructure: 'Meniscos medial y lateral',
      patientPosition: 'Decúbito supino con rodilla y cadera flexionadas por completo.',
      examinerAction: 'Para menisco medial: rotación externa tibial + estrés en valgo mientras se extiende la rodilla lentamente. Para lateral: rotación interna + estrés en varo en extensión.',
      positiveFinding: 'Chasquido palpable o audible, o dolor agudo localizado en la interlínea articular.',
      clinicalInterpretation: 'Lesión o rotura de los cuernos meniscales (medial o lateral según maniobra).',
      sensitivity: '55% - 70%',
      specificity: '77% - 90%',
      tags: ['rodilla', 'menisco', 'mcmurray', 'articulacion'],
    ),
    const OrthopedicTest(
      id: 'rodilla-cajon-post',
      name: 'Test del Cajón Posterior',
      region: JointRegion.knee,
      targetStructure: 'Ligamento Cruzado Posterior (LCP)',
      patientPosition: 'Decúbito supino, cadera en 45° y rodilla flexionada a 90°, pie apoyado en camilla.',
      examinerAction: 'Examinador fija el pie sentándose suavemente sobre él, abraza la tibia proximal con ambos pulgares sobre la tuberosidad anterior y empuja posteriormente.',
      positiveFinding: 'Traslación posterior anormal de la tibia respecto a los cóndilos femorales.',
      clinicalInterpretation: 'Rotura o insuficiencia del Ligamento Cruzado Posterior.',
      sensitivity: '89% - 99%',
      specificity: '99%',
      tags: ['rodilla', 'lcp', 'cajon posterior', 'ligamento'],
    ),

    // ─── COLUMNA VERTEBRAL ──────────────────────────────────────────────────
    const OrthopedicTest(
      id: 'columna-spurling',
      name: 'Test de Spurling (Compresión Cervical)',
      region: JointRegion.spine,
      targetStructure: 'Raíz nerviosa cervical (Radiculopatía cervical / Foramen intervertebral)',
      patientPosition: 'Sedente con tronco erguido.',
      examinerAction: 'El paciente inclina la cabeza hacia el lado afecto con ligera rotación y extensión; el terapeuta aplica una fuerza de compresión axial vertical controlada sobre la coronilla.',
      positiveFinding: 'Aparición o exacerbación del dolor u hormigueo irradiado hacia el brazo o mano en el dermatoma correspondiente.',
      clinicalInterpretation: 'Radiculopatía cervical por hernia discal o estenosis foraminal.',
      sensitivity: '50% - 65%',
      specificity: '93% - 100%',
      tags: ['columna', 'cervical', 'radiculopatia', 'spurling', 'ciatica cervical'],
    ),
    const OrthopedicTest(
      id: 'columna-lasegue',
      name: 'Test de Lasègue (SLR - Straight Leg Raise)',
      region: JointRegion.spine,
      targetStructure: 'Nervio Ciático y raíces lumbares (L4, L5, S1)',
      patientPosition: 'Decúbito supino con piernas extendidas y cuello relajado.',
      examinerAction: 'El examinador eleva pasivamente la pierna afecta con rodilla completamente extendida hasta que aparezca síntoma o hasta 70-80°.',
      positiveFinding: 'Dolor ciático irradiado de carácter punzante/eléctrico por debajo de la rodilla entre los 35° y 70° de elevación.',
      clinicalInterpretation: 'Irritación o compresión del nervio ciático / hernia discal lumbar.',
      sensitivity: '91%',
      specificity: '41% - 60%',
      tags: ['columna', 'lumbar', 'ciatica', 'lasegue', 'disco'],
    ),
    const OrthopedicTest(
      id: 'columna-slump',
      name: 'Slump Test (Test de Desplome Neural)',
      region: JointRegion.spine,
      targetStructure: 'Mecanodinamia del neuroeje (Médula, meninges y raíces lumbares)',
      patientPosition: 'Sentado en el borde de la camilla con rodillas en 90° y muslos apoyados.',
      examinerAction: 'Progresión: 1. Colapso toracolumbar (espalda encorvada) 2. Flexión cervical 3. Extensión de rodilla 4. Dorsiflexión de tobillo. Si hay dolor, se libera la flexión cervical.',
      positiveFinding: 'Reproducción de dolor radicular que disminuye o desaparece al extender el cuello.',
      clinicalInterpretation: 'Sensibilización o restricción de la movilidad del tejido neural espinal.',
      sensitivity: '84%',
      specificity: '83%',
      tags: ['columna', 'neurodinamica', 'slump', 'nervio'],
    ),

    // ─── CADERA ─────────────────────────────────────────────────────────────
    const OrthopedicTest(
      id: 'cadera-faber',
      name: 'Test de Patrick (FABER)',
      region: JointRegion.hip,
      targetStructure: 'Articulación Sacroilíaca y articulación Coxofemoral',
      patientPosition: 'Decúbito supino.',
      examinerAction: 'Se coloca la pierna en Flexión, ABducción y Rotación Externa (pie reposando sobre la rodilla opuesta en forma de "4"). El examinador estabiliza la pelvis contraria y presiona la rodilla hacia la camilla.',
      positiveFinding: 'Dolor en la zona glútea/sacroilíaca posterior (indica sacroilitis) o dolor en la ingle anterior (indica patología coxofemoral).',
      clinicalInterpretation: 'Disfunción articular sacroilíaca o choque femoroacetabular / artrosis de cadera.',
      sensitivity: '77% - 82%',
      specificity: '85% - 90%',
      tags: ['cadera', 'sacroiliaca', 'faber', 'patrick', 'coxofemoral'],
    ),
    const OrthopedicTest(
      id: 'cadera-thomas',
      name: 'Test de Thomas',
      region: JointRegion.hip,
      targetStructure: 'Músculo Psoas Ilíaco y Recto Anterior del cuádriceps',
      patientPosition: 'Decúbito supino en el extremo de la camilla.',
      examinerAction: 'El paciente flexiona una cadera y rodilla hacia el pecho con las manos para anular la lordosis lumbar. La pierna evaluada cuelga libremente.',
      positiveFinding: 'El muslo de la pierna evaluada se levanta de la camilla (psoas tenso) o la rodilla se extiende a más de 90° (recto femoral tenso).',
      clinicalInterpretation: 'Acortamiento o contractura flexora de cadera.',
      sensitivity: '72%',
      specificity: '78%',
      tags: ['cadera', 'psoas', 'flexores', 'thomas', 'acortamiento'],
    ),

    // ─── CODO Y MUÑECA ──────────────────────────────────────────────────────
    const OrthopedicTest(
      id: 'codo-cozen',
      name: 'Test de Cozen',
      region: JointRegion.elbowWrist,
      targetStructure: 'Tendones extensores de muñeca (Epicóndilo lateral / Codo de tenista)',
      patientPosition: 'Sedente con codo flexionado en 90° y antebrazo en pronación.',
      examinerAction: 'Examinador fija el codo y palpa el epicóndilo con el pulgar; pide al paciente que cierre el puño, haga desviación radial y extienda la muñeca contra resistencia.',
      positiveFinding: 'Dolor punzante e intenso en el epicóndilo lateral humeral.',
      clinicalInterpretation: 'Epicondilalgia lateral (Codo de tenista) por afectación del extensor radial corto del carpo.',
      sensitivity: '84% - 91%',
      specificity: '78% - 85%',
      tags: ['codo', 'epicondilitis', 'cozen', 'tenista', 'extensores'],
    ),
    const OrthopedicTest(
      id: 'muneca-phalen',
      name: 'Test de Phalen',
      region: JointRegion.elbowWrist,
      targetStructure: 'Nervio Mediano en el Túnel del Carpo',
      patientPosition: 'Sedente con codos apoyados.',
      examinerAction: 'El paciente junta los dorsos de ambas manos en flexión completa de 90° de muñecas durante 60 segundos.',
      positiveFinding: 'Aparición de parestesias, adormecimiento o entumecimiento en territorio del nervio mediano (pulgar, índice, medio y mitad radial del anular).',
      clinicalInterpretation: 'Síndrome del Túnel Carpiano por compresión mecánica.',
      sensitivity: '68% - 88%',
      specificity: '75% - 90%',
      tags: ['muneca', 'tunel carpiano', 'phalen', 'nervio mediano'],
    ),
    const OrthopedicTest(
      id: 'muneca-finkelstein',
      name: 'Test de Finkelstein',
      region: JointRegion.elbowWrist,
      targetStructure: 'Tendones del Extensor Corto y Abductor Largo del pulgar',
      patientPosition: 'Sedente con antebrazo en posición neutra.',
      examinerAction: 'El paciente cierra la mano colocando el pulgar dentro de los otros 4 dedos (puño cerrado con pulgar atrapado) y el terapeuta induce una desviación cubital pasiva.',
      positiveFinding: 'Dolor lacerante o punzante en la estiloides radial a lo largo del primer compartimento dorsal extensor.',
      clinicalInterpretation: 'Tenosinovitis de De Quervain.',
      sensitivity: '89%',
      specificity: '95%',
      tags: ['muneca', 'de quervain', 'finkelstein', 'pulgar', 'estiloides'],
    ),

    // ─── TOBILLO Y PIE ──────────────────────────────────────────────────────
    const OrthopedicTest(
      id: 'tobillo-thompson',
      name: 'Test de Thompson (Simmonds)',
      region: JointRegion.ankleFoot,
      targetStructure: 'Tendón de Aquiles',
      patientPosition: 'Decúbito prono con los pies colgando por fuera de la camilla.',
      examinerAction: 'El terapeuta comprime manualmente el vientre muscular de la masa gemelar / tríceps sural con una mano.',
      positiveFinding: 'Ausencia total de flexión plantar refleja involuntaria del pie al apretar la pantorrilla.',
      clinicalInterpretation: 'Rotura completa del Tendón de Aquiles.',
      sensitivity: '96% - 98%',
      specificity: '93% - 98%',
      tags: ['tobillo', 'aquiles', 'thompson', 'rotura tendinosa'],
    ),
    const OrthopedicTest(
      id: 'tobillo-cajon-ant',
      name: 'Cajón Anterior de Tobillo',
      region: JointRegion.ankleFoot,
      targetStructure: 'Ligamento Peroneoastragalino Anterior (LPAA)',
      patientPosition: 'Sedente con rodilla flexionada 90° y tobillo en ligera flexión plantar (10°).',
      examinerAction: 'El examinador fija la tibia distal con una mano y con la otra abraza el talón/calcáneo tirando hacia adelante.',
      positiveFinding: 'Desplazamiento anterior excesivo del astrágalo fuera de la mortaja o sensación de hoyuelo ("suction sign") en la cara anterolateral.',
      clinicalInterpretation: 'Esguince con rotura o distensión severa del ligamento LPAA de tobillo.',
      sensitivity: '73% - 86%',
      specificity: '88% - 92%',
      tags: ['tobillo', 'esguince', 'lpaa', 'cajon anterior', 'inestabilidad'],
    ),
  ];

  static List<OrthopedicTest> getByRegion(JointRegion region) {
    return allTests.where((test) => test.region == region).toList();
  }

  static List<OrthopedicTest> search(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return allTests;
    return allTests.where((test) {
      final matchesName = test.name.toLowerCase().contains(clean);
      final matchesTarget = test.targetStructure.toLowerCase().contains(clean);
      final matchesRegion = test.region.displayName.toLowerCase().contains(clean);
      final matchesTags = test.tags.any((t) => t.toLowerCase().contains(clean));
      return matchesName || matchesTarget || matchesRegion || matchesTags;
    }).toList();
  }
}
