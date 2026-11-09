// test/domain/entities_test.dart
// Phase 1 unit tests: validates serialization round-trips and business logic
// for all 8 canonical entities and the CurriculumFilter/SortOrder models.

import 'package:flutter_test/flutter_test.dart';
import 'package:ethio_it_exitprep/domain/entities/program_theme.dart';
import 'package:ethio_it_exitprep/domain/entities/course.dart';
import 'package:ethio_it_exitprep/domain/entities/chapter.dart';
import 'package:ethio_it_exitprep/domain/entities/study_material.dart';
import 'package:ethio_it_exitprep/domain/entities/content_relation.dart';
import 'package:ethio_it_exitprep/domain/entities/question.dart';
import 'package:ethio_it_exitprep/domain/entities/question_option.dart';
import 'package:ethio_it_exitprep/domain/entities/student_progress.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_filter.dart';
import 'package:ethio_it_exitprep/core/constants/curriculum_constants.dart';

void main() {
  final now = DateTime(2026, 11, 9);

  // ── 1. ProgramTheme ────────────────────────────────────────────────────────
  group('ProgramTheme', () {
    final theme = ProgramTheme(
      id: 'T1',
      title: 'Programming & Software Engineering',
      themeCode: 'PROG',
      blueprintSharePct: 23.0,
      priorityRank: 1,
      createdAt: now,
      updatedAt: now,
    );

    test('toJson / fromJson round-trip', () {
      final json = theme.toJson();
      final restored = ProgramTheme.fromJson(json);
      expect(restored.id, theme.id);
      expect(restored.themeCode, theme.themeCode);
      expect(restored.blueprintSharePct, theme.blueprintSharePct);
      expect(restored.priorityRank, theme.priorityRank);
    });

    test('copyWith preserves unchanged fields', () {
      final copy = theme.copyWith(priorityRank: 2);
      expect(copy.priorityRank, 2);
      expect(copy.themeCode, theme.themeCode);
    });
  });

  // ── 2. Course ──────────────────────────────────────────────────────────────
  group('Course', () {
    final course = Course(
      id: 'C01',
      title: 'Object-Oriented Programming',
      themeId: 'T1',
      courseCode: 'ITec2051',
      creditHours: 3,
      examWeightPct: 8.0,
      priorityLevel: 'P1',
      createdAt: now,
      updatedAt: now,
    );

    test('toJson / fromJson round-trip', () {
      final restored = Course.fromJson(course.toJson());
      expect(restored.courseCode, 'ITec2051');
      expect(restored.examWeightPct, 8.0);
      expect(restored.priorityLevel, 'P1');
    });
  });

  // ── 3. Chapter ─────────────────────────────────────────────────────────────
  group('Chapter', () {
    final chapter = Chapter(
      id: 'CH01',
      title: 'Introduction to OOP',
      courseId: 'C01',
      chapterNumber: 1,
      sequenceOrder: 1,
      priorityScore: 90.0,
      estMinutes: 45,
      createdAt: now,
      updatedAt: now,
    );

    test('toJson / fromJson round-trip', () {
      final restored = Chapter.fromJson(chapter.toJson());
      expect(restored.priorityScore, 90.0);
      expect(restored.chapterNumber, 1);
    });
  });

  // ── 4. StudyMaterial ───────────────────────────────────────────────────────
  group('StudyMaterial', () {
    final material = StudyMaterial(
      id: 'SM01',
      title: 'Classes and Objects',
      chapterId: 'CH01',
      contentStyle: ContentStyle.conceptNote,
      difficultyTier: DifficultyTier.moderate,
      priorityTier: PriorityTier.p1Critical,
      contentBlocks: [{'type': 'markdown', 'text': '# OOP'}],
      tags: ['oop', 'class'],
      createdAt: now,
      updatedAt: now,
    );

    test('toJson / fromJson round-trip', () {
      final restored = StudyMaterial.fromJson(material.toJson());
      expect(restored.contentStyle, ContentStyle.conceptNote);
      expect(restored.difficultyTier, DifficultyTier.moderate);
      expect(restored.priorityTier, PriorityTier.p1Critical);
      expect(restored.tags, contains('oop'));
    });

    test('difficultyTier maps to correct level int', () {
      expect(DifficultyTier.simple.level, 1);
      expect(DifficultyTier.moderate.level, 2);
      expect(DifficultyTier.hard.level, 3);
    });

    test('priorityTier maps to correct string', () {
      expect(PriorityTier.p1Critical.value, 'P1_CRITICAL');
      expect(PriorityTier.p2HighYield.value, 'P2_HIGH_YIELD');
      expect(PriorityTier.p3Supplementary.value, 'P3_SUPPLEMENTARY');
    });
  });

  // ── 5. ContentRelation ─────────────────────────────────────────────────────
  group('ContentRelation', () {
    final relation = ContentRelation(
      relationId: 'R01',
      sourceType: 'question',
      sourceId: 'Q01',
      targetType: 'material',
      targetId: 'SM01',
      relationType: RelationType.explainsAnswerFor,
      relevanceWeight: 0.9,
    );

    test('toJson / fromJson round-trip', () {
      final restored = ContentRelation.fromJson(relation.toJson());
      expect(restored.relationType, RelationType.explainsAnswerFor);
      expect(restored.relationType.value, 'EXPLAINS_ANSWER_FOR');
      expect(restored.relevanceWeight, 0.9);
    });
  });

  // ── 6. Question ───────────────────────────────────────────────────────────
  group('Question', () {
    final question = Question(
      id: 'Q01',
      title: 'What is encapsulation?',
      courseId: 'C01',
      chapterId: 'CH01',
      examYear: 2017,
      sourceType: SourceType.nationalExitExam,
      difficultyTier: DifficultyTier.simple,
      priorityWeight: 80.0,
      bloomDomain: BloomDomain.cognitive,
      stemTitle: 'Encapsulation',
      stemBody: 'Which of the following best describes encapsulation?',
      generalExplanation: 'Encapsulation bundles data and methods.',
      createdAt: now,
      updatedAt: now,
    );

    test('toJson / fromJson round-trip', () {
      final restored = Question.fromJson(question.toJson());
      expect(restored.examYear, 2017);
      expect(restored.sourceType, SourceType.nationalExitExam);
      expect(restored.bloomDomain, BloomDomain.cognitive);
    });

    test('sourceType values are correct', () {
      expect(SourceType.nationalExitExam.value, 'NATIONAL_EXIT_EXAM');
      expect(SourceType.universityMock.value, 'UNIVERSITY_MOCK');
      expect(SourceType.courseDrill.value, 'COURSE_DRILL');
    });
  });

  // ── 7. QuestionOption ─────────────────────────────────────────────────────
  group('QuestionOption', () {
    final option = QuestionOption(
      optionId: 'OPT01',
      questionId: 'Q01',
      optionKey: 'A',
      optionText: 'Bundling data and methods together',
      isCorrect: true,
      optionRationale: 'Encapsulation is about bundling.',
    );

    test('toJson / fromJson round-trip', () {
      final restored = QuestionOption.fromJson(option.toJson());
      expect(restored.isCorrect, true);
      expect(restored.optionKey, 'A');
    });
  });

  // ── 8. StudentProgress & ExamAttempt ──────────────────────────────────────
  group('StudentProgress', () {
    final mastery = ChapterMastery(
      chapterId: 'CH01',
      masteryPct: 0.75,
      questionsAttempted: 20,
      questionsCorrect: 15,
      lastStudied: now,
    );

    final attempt = ExamAttempt(
      attemptId: 'ATT01',
      studentId: 'STU01',
      startedAt: now,
      completedAt: now.add(const Duration(hours: 2)),
      totalQuestions: 100,
      correctAnswers: 72,
      scorePercent: 72.0,
      answerMap: {'Q01': 'A'},
    );

    final progress = StudentProgress(
      studentId: 'STU01',
      masteryByChapter: {'CH01': mastery},
      bookmarkedIds: ['SM01'],
      examAttempts: [attempt],
      lastSynced: now,
    );

    test('overallReadiness calculates correctly', () {
      expect(progress.overallReadiness, closeTo(75.0, 0.01));
    });

    test('ExamAttempt toJson / fromJson round-trip', () {
      final restored = ExamAttempt.fromJson(attempt.toJson());
      expect(restored.scorePercent, 72.0);
      expect(restored.syncedToCloud, false);
    });

    test('StudentProgress toJson / fromJson round-trip', () {
      final restored = StudentProgress.fromJson(progress.toJson());
      expect(restored.studentId, 'STU01');
      expect(restored.bookmarkedIds, contains('SM01'));
      expect(restored.masteryByChapter['CH01']?.masteryPct, 0.75);
    });
  });

  // ── 9. CurriculumFilter ───────────────────────────────────────────────────
  group('CurriculumFilter', () {
    test('empty filter has no active filters', () {
      expect(CurriculumFilter.empty.hasFilters, false);
    });

    test('filter with one field has active filters', () {
      const f = CurriculumFilter(courseId: 'C01');
      expect(f.hasFilters, true);
    });

    test('copyWith preserves existing fields and overrides specified ones', () {
      const f = CurriculumFilter(courseId: 'C01', examYear: 2017);
      final f2 = f.copyWith(examYear: 2018);
      expect(f2.courseId, 'C01');
      expect(f2.examYear, 2018);
    });
  });

  // ── 10. CurriculumSortOrder SQL ───────────────────────────────────────────
  group('CurriculumSortOrder SQL clauses', () {
    test('priorityDesc generates correct SQL', () {
      expect(
        CurriculumSortOrder.priorityDesc.toSqlOrderBy(),
        'priority_score DESC, difficulty_tier ASC',
      );
    });

    test('weaknessFirst generates correct SQL', () {
      expect(
        CurriculumSortOrder.weaknessFirst.toSqlOrderBy(),
        '(priority_score * (1.0 - mastery_pct)) DESC',
      );
    });

    test('all sort orders produce non-empty SQL', () {
      for (final order in CurriculumSortOrder.values) {
        expect(order.toSqlOrderBy().isNotEmpty, true, reason: '${order.name} had empty SQL');
      }
    });
  });

  // ── 11. CurriculumConstants ───────────────────────────────────────────────
  group('CurriculumConstants', () {
    test('has 5 themes', () {
      expect(CurriculumConstants.themes.length, 5);
    });

    test('has 13 courses', () {
      expect(CurriculumConstants.courses.length, 13);
    });

    test('all courses have themeId', () {
      for (final c in CurriculumConstants.courses) {
        expect(c['themeId'], isNotNull, reason: '${c['code']} missing themeId');
      }
    });

    test('all theme blueprintSharePct sums to 100', () {
      final total = CurriculumConstants.themes
          .fold<double>(0, (sum, t) => sum + (t['blueprintSharePct'] as double));
      expect(total, closeTo(100.0, 0.1));
    });
  });
}
