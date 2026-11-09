// lib/core/constants/curriculum_constants.dart
// MoE FDRE National Exit Exam Blueprint constants for the 5 themes & 13 BSc IT courses.

class CurriculumConstants {
  CurriculumConstants._();

  // ── 5 Programme Themes ──────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> themes = [
    {'id': 'T1', 'code': 'PROG', 'title': 'Programming & Software Engineering', 'blueprintSharePct': 23.0, 'priorityRank': 1},
    {'id': 'T2', 'code': 'DATA', 'title': 'Data Management & Information Systems', 'blueprintSharePct': 22.0, 'priorityRank': 2},
    {'id': 'T3', 'code': 'NET',  'title': 'Computer Networking & Security', 'blueprintSharePct': 20.0, 'priorityRank': 3},
    {'id': 'T4', 'code': 'WEB',  'title': 'Web & Mobile Development', 'blueprintSharePct': 18.0, 'priorityRank': 4},
    {'id': 'T5', 'code': 'SYS',  'title': 'System Analysis & Administration', 'blueprintSharePct': 17.0, 'priorityRank': 5},
  ];

  // ── 13 Core BSc IT Courses (45 credit hours) ────────────────────────────────
  static const List<Map<String, dynamic>> courses = [
    // Theme T1 – Programming & Software Engineering
    {'id': 'C01', 'themeId': 'T1', 'code': 'ITec2051', 'title': 'Object-Oriented Programming', 'creditHours': 3, 'examWeightPct': 8.0, 'priorityLevel': 'P1'},
    {'id': 'C02', 'themeId': 'T1', 'code': 'ITec3061', 'title': 'Data Structures & Algorithms', 'creditHours': 3, 'examWeightPct': 8.0, 'priorityLevel': 'P1'},
    {'id': 'C03', 'themeId': 'T1', 'code': 'ITec4051', 'title': 'Software Engineering', 'creditHours': 3, 'examWeightPct': 7.0, 'priorityLevel': 'P1'},
    // Theme T2 – Data Management
    {'id': 'C04', 'themeId': 'T2', 'code': 'ITec2041', 'title': 'Database Systems', 'creditHours': 3, 'examWeightPct': 8.0, 'priorityLevel': 'P1'},
    {'id': 'C05', 'themeId': 'T2', 'code': 'ITec3041', 'title': 'Advanced Database Systems', 'creditHours': 3, 'examWeightPct': 7.0, 'priorityLevel': 'P1'},
    {'id': 'C06', 'themeId': 'T2', 'code': 'ITec4041', 'title': 'Information Systems', 'creditHours': 3, 'examWeightPct': 7.0, 'priorityLevel': 'P2'},
    // Theme T3 – Networking & Security
    {'id': 'C07', 'themeId': 'T3', 'code': 'ITec3031', 'title': 'Computer Networks', 'creditHours': 3, 'examWeightPct': 8.0, 'priorityLevel': 'P1'},
    {'id': 'C08', 'themeId': 'T3', 'code': 'ITec4031', 'title': 'Network Security', 'creditHours': 3, 'examWeightPct': 7.0, 'priorityLevel': 'P1'},
    {'id': 'C09', 'themeId': 'T3', 'code': 'ITec3032', 'title': 'Operating Systems', 'creditHours': 3, 'examWeightPct': 5.0, 'priorityLevel': 'P2'},
    // Theme T4 – Web & Mobile
    {'id': 'C10', 'themeId': 'T4', 'code': 'ITec3071', 'title': 'Web Technologies', 'creditHours': 3, 'examWeightPct': 8.0, 'priorityLevel': 'P1'},
    {'id': 'C11', 'themeId': 'T4', 'code': 'ITec4103', 'title': 'Mobile Application Development', 'creditHours': 3, 'examWeightPct': 7.0, 'priorityLevel': 'P1'},
    // Theme T5 – Systems & Analysis
    {'id': 'C12', 'themeId': 'T5', 'code': 'ITec3011', 'title': 'Systems Analysis & Design', 'creditHours': 3, 'examWeightPct': 8.0, 'priorityLevel': 'P1'},
    {'id': 'C13', 'themeId': 'T5', 'code': 'ITec4011', 'title': 'IT Project Management', 'creditHours': 3, 'examWeightPct': 7.0, 'priorityLevel': 'P2'},
  ];

  // ── Difficulty Tiers ────────────────────────────────────────────────────────
  static const int difficultySimple   = 1;
  static const int difficultyModerate = 2;
  static const int difficultyHard     = 3;

  // ── Priority Tiers ──────────────────────────────────────────────────────────
  static const String priorityCritical      = 'P1_CRITICAL';
  static const String priorityHighYield     = 'P2_HIGH_YIELD';
  static const String prioritySupplementary = 'P3_SUPPLEMENTARY';

  // ── Exam Years (Ethiopian Calendar) ────────────────────────────────────────
  static const List<int> examYears = [2015, 2016, 2017, 2018];
}
