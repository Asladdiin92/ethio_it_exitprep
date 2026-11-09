// lib/data/local/seed_data.dart
// Pre-bundled seed loader for the 5 MoE themes and 13 BSc IT courses.
// Called once on first launch to populate the local SQLite database.

import 'package:ethio_it_exitprep/core/constants/curriculum_constants.dart';
import 'package:ethio_it_exitprep/domain/entities/program_theme.dart';
import 'package:ethio_it_exitprep/domain/entities/course.dart';
import 'package:ethio_it_exitprep/domain/entities/chapter.dart';
import 'package:ethio_it_exitprep/domain/entities/question.dart';
import 'package:ethio_it_exitprep/domain/entities/question_option.dart';
import 'package:ethio_it_exitprep/domain/entities/study_material.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_repository.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_filter.dart';

class SeedDataLoader {
  final ProgramThemeRepository themeRepo;
  final CourseRepository courseRepo;
  final ChapterRepository? chapterRepo;
  final QuestionRepository? questionRepo;
  final QuestionOptionRepository? optionRepo;

  SeedDataLoader({
    required this.themeRepo,
    required this.courseRepo,
    this.chapterRepo,
    this.questionRepo,
    this.optionRepo,
  });

  /// Seeds the database with baseline curriculum data.
  /// Uses INSERT OR REPLACE so it is safe to call multiple times.
  Future<void> loadIfEmpty() async {
    final themes = await themeRepo.getAll();
    if (themes.isEmpty) {
      await _seedThemes();
      await _seedCourses();
    }

    if (chapterRepo != null && questionRepo != null && optionRepo != null) {
      final questions = await questionRepo!.query(const CurriculumFilter());
      if (questions.isEmpty) {
        await _seedSampleChaptersAndQuestions();
      }
    }
  }

  Future<void> _seedThemes() async {
    final now = DateTime.now();
    final entities = CurriculumConstants.themes.map((t) => ProgramTheme(
          id: t['id'] as String,
          themeCode: t['code'] as String,
          title: t['title'] as String,
          blueprintSharePct: (t['blueprintSharePct'] as num).toDouble(),
          priorityRank: t['priorityRank'] as int,
          createdAt: now,
          updatedAt: now,
        ));
    await themeRepo.upsertAll(entities.toList());
  }

  Future<void> _seedCourses() async {
    final now = DateTime.now();
    final entities = CurriculumConstants.courses.map((c) => Course(
          id: c['id'] as String,
          themeId: c['themeId'] as String,
          courseCode: c['code'] as String,
          title: c['title'] as String,
          creditHours: c['creditHours'] as int,
          examWeightPct: (c['examWeightPct'] as num).toDouble(),
          priorityLevel: c['priorityLevel'] as String,
          createdAt: now,
          updatedAt: now,
        ));
    await courseRepo.upsertAll(entities.toList());
  }

  Future<void> _seedSampleChaptersAndQuestions() async {
    final now = DateTime.now();

    // Baseline chapters for sample questions
    final chapters = [
      Chapter(
        id: 'C01_CH1',
        courseId: 'C01',
        title: 'Object-Oriented Programming Fundamentals & Encapsulation',
        chapterNumber: 1,
        sequenceOrder: 1,
        priorityScore: 95.0,
        estMinutes: 60,
        createdAt: now,
        updatedAt: now,
      ),
      Chapter(
        id: 'C07_CH1',
        courseId: 'C07',
        title: 'OSI and TCP/IP Architecture',
        chapterNumber: 1,
        sequenceOrder: 1,
        priorityScore: 90.0,
        estMinutes: 60,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    await chapterRepo!.upsertAll(chapters);

    // Sample Exit Exam Questions from curriculum seed
    final sampleQuestions = [
      Question(
        id: 'Q_2017_OOP_01',
        courseId: 'C01',
        chapterId: 'C01_CH1',
        title: 'Object-Oriented Encapsulation',
        description: 'National Exit Exam 2017 E.C. - OOP',
        examYear: 2017,
        sourceType: SourceType.nationalExitExam,
        difficultyTier: DifficultyTier.simple,
        priorityWeight: 85.0,
        bloomDomain: BloomDomain.cognitive,
        stemTitle: 'Object-Oriented Encapsulation',
        stemBody: "In object-oriented programming, which mechanism restricts direct access to some of an object's components?",
        generalExplanation: "Encapsulation prevents client code from directly seeing and mutating an object's internal state.",
        createdAt: now,
        updatedAt: now,
      ),
      Question(
        id: 'Q_2018_NET_01',
        courseId: 'C07',
        chapterId: 'C07_CH1',
        title: 'OSI Transport Layer Protocol',
        description: 'National Exit Exam 2018 E.C. - Computer Networking',
        examYear: 2018,
        sourceType: SourceType.nationalExitExam,
        difficultyTier: DifficultyTier.moderate,
        priorityWeight: 88.0,
        bloomDomain: BloomDomain.cognitive,
        stemTitle: 'OSI Transport Layer Protocol',
        stemBody: 'Which protocol operates at the Transport layer to provide reliable, connection-oriented data transmission?',
        generalExplanation: 'TCP provides reliable, sequenced delivery with three-way handshaking and error checking.',
        createdAt: now,
        updatedAt: now,
      ),
    ];
    await questionRepo!.upsertAll(sampleQuestions);

    // Options for Q_2017_OOP_01
    final optionsQ1 = [
      const QuestionOption(
        optionId: 'OPT_OOP_01_A',
        questionId: 'Q_2017_OOP_01',
        optionKey: 'A',
        optionText: 'Inheritance',
        isCorrect: false,
        optionRationale: 'Inheritance establishes an is-a hierarchy, not access restriction.',
      ),
      const QuestionOption(
        optionId: 'OPT_OOP_01_B',
        questionId: 'Q_2017_OOP_01',
        optionKey: 'B',
        optionText: 'Encapsulation',
        isCorrect: true,
        optionRationale: 'Encapsulation bundles data with functions and restricts direct outside access via private/protected scopes.',
      ),
      const QuestionOption(
        optionId: 'OPT_OOP_01_C',
        questionId: 'Q_2017_OOP_01',
        optionKey: 'C',
        optionText: 'Polymorphism',
        isCorrect: false,
        optionRationale: 'Polymorphism allows objects to take multiple forms at runtime.',
      ),
      const QuestionOption(
        optionId: 'OPT_OOP_01_D',
        questionId: 'Q_2017_OOP_01',
        optionKey: 'D',
        optionText: 'Dynamic Linking',
        isCorrect: false,
        optionRationale: 'Dynamic linking resolves module references at load time.',
      ),
    ];

    // Options for Q_2018_NET_01
    final optionsQ2 = [
      const QuestionOption(
        optionId: 'OPT_NET_01_A',
        questionId: 'Q_2018_NET_01',
        optionKey: 'A',
        optionText: 'User Datagram Protocol (UDP)',
        isCorrect: false,
        optionRationale: 'UDP is connectionless and does not guarantee delivery.',
      ),
      const QuestionOption(
        optionId: 'OPT_NET_01_B',
        questionId: 'Q_2018_NET_01',
        optionKey: 'B',
        optionText: 'Internet Protocol (IP)',
        isCorrect: false,
        optionRationale: 'IP operates at the Network Layer (Layer 3).',
      ),
      const QuestionOption(
        optionId: 'OPT_NET_01_C',
        questionId: 'Q_2018_NET_01',
        optionKey: 'C',
        optionText: 'Transmission Control Protocol (TCP)',
        isCorrect: true,
        optionRationale: 'TCP provides full-duplex, sequence-controlled, reliable communication.',
      ),
      const QuestionOption(
        optionId: 'OPT_NET_01_D',
        questionId: 'Q_2018_NET_01',
        optionKey: 'D',
        optionText: 'Address Resolution Protocol (ARP)',
        isCorrect: false,
        optionRationale: 'ARP operates between the Data Link and Network layers.',
      ),
    ];

    await optionRepo!.upsertAll([...optionsQ1, ...optionsQ2]);
  }
}
