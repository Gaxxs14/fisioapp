enum JointRegion {
  shoulder,
  knee,
  spine,
  hip,
  elbowWrist,
  ankleFoot;

  String get displayName {
    switch (this) {
      case JointRegion.shoulder:
        return 'Hombro';
      case JointRegion.knee:
        return 'Rodilla';
      case JointRegion.spine:
        return 'Columna';
      case JointRegion.hip:
        return 'Cadera';
      case JointRegion.elbowWrist:
        return 'Codo / Muñeca';
      case JointRegion.ankleFoot:
        return 'Tobillo / Pie';
    }
  }

  String get displayNameEn {
    switch (this) {
      case JointRegion.shoulder:
        return 'Shoulder';
      case JointRegion.knee:
        return 'Knee';
      case JointRegion.spine:
        return 'Spine';
      case JointRegion.hip:
        return 'Hip';
      case JointRegion.elbowWrist:
        return 'Elbow / Wrist';
      case JointRegion.ankleFoot:
        return 'Ankle / Foot';
    }
  }
}

class OrthopedicTest {
  final String id;
  final String name;
  final JointRegion region;
  final String targetStructure;
  final String patientPosition;
  final String examinerAction;
  final String positiveFinding;
  final String clinicalInterpretation;
  final String sensitivity;
  final String specificity;
  final List<String> tags;

  const OrthopedicTest({
    required this.id,
    required this.name,
    required this.region,
    required this.targetStructure,
    required this.patientPosition,
    required this.examinerAction,
    required this.positiveFinding,
    required this.clinicalInterpretation,
    required this.sensitivity,
    required this.specificity,
    this.tags = const [],
  });
}
