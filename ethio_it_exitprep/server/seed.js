// Idempotent curriculum migration from the checked-in JSON seed into MongoDB.
require('dotenv').config();
const fs = require('node:fs/promises');
const path = require('node:path');
const mongoose = require('mongoose');
const {
  Theme,
  Course,
  Chapter,
  StudyMaterial,
  ContentRelation,
  Question,
  QuestionOption,
} = require('./src/models');

const MONGODB_URI = process.env.MONGODB_URI || process.env.MONGO_URI;
const seedPath = path.resolve(__dirname, '../assets/seed/curriculum_seed.json');

const defaultCourses = [
  ['C01', 'T1', 'ITec2051', 'Object-Oriented Programming', 8, 'P1'],
  ['C02', 'T1', 'ITec3061', 'Data Structures & Algorithms', 8, 'P1'],
  ['C03', 'T1', 'ITec4051', 'Software Engineering', 7, 'P1'],
  ['C04', 'T2', 'ITec2041', 'Database Systems', 8, 'P1'],
  ['C05', 'T2', 'ITec3041', 'Advanced Database Systems', 7, 'P1'],
  ['C06', 'T2', 'ITec4041', 'Information Systems', 7, 'P2'],
  ['C07', 'T3', 'ITec3031', 'Computer Networks', 8, 'P1'],
  ['C08', 'T3', 'ITec4031', 'Network Security', 7, 'P1'],
  ['C09', 'T3', 'ITec3032', 'Operating Systems', 5, 'P2'],
  ['C10', 'T4', 'ITec3071', 'Web Technologies', 8, 'P1'],
  ['C11', 'T4', 'ITec4103', 'Mobile Application Development', 7, 'P1'],
  ['C12', 'T5', 'ITec3011', 'Systems Analysis & Design', 8, 'P1'],
  ['C13', 'T5', 'ITec4011', 'IT Project Management', 7, 'P2'],
];

async function upsert(Model, filter, document, now) {
  await Model.updateOne(
    filter,
    { $set: { ...document, updatedAt: now }, $setOnInsert: { createdAt: now } },
    { upsert: true },
  );
}

function normalizeCourse(course) {
  return {
    id: course.id,
    themeId: course.themeId,
    courseCode: course.courseCode || course.code,
    title: course.title,
    description: course.description,
    courseYear: course.courseYear ?? course.year ?? 1,
    semester: course.semester ?? 1,
    creditHours: course.creditHours ?? 3,
    examWeightPct: course.examWeightPct ?? 0,
    priorityLevel: course.priorityLevel || 'P2',
    customAttributes: course.customAttributes || {},
  };
}

function normalizeQuestion(question, courseByCode, courseById) {
  const course = courseById.get(question.courseId) || courseByCode.get(question.courseCode);
  if (!course) throw new Error(`Unknown course for question ${question.id}`);
  return {
    id: question.id,
    courseId: course.id,
    chapterId: question.chapterId || `${course.id}_CH1`,
    linkedMaterialId: question.linkedMaterialId,
    title: question.title || question.stemTitle,
    description: question.description || `${question.sourceType || 'PRACTICE'} ${question.examYear || ''}`.trim(),
    examYear: question.examYear ?? 0,
    sourceType: question.sourceType || 'PRACTICE',
    difficultyTier: question.difficultyTier ?? 1,
    priorityWeight: question.priorityWeight ?? 50,
    bloomDomain: question.bloomDomain || 'cognitive',
    stemTitle: question.stemTitle || question.title,
    stemBody: question.stemBody || question.body || '',
    generalExplanation: question.generalExplanation || question.explanation || '',
    customAttributes: question.customAttributes || {},
    course,
  };
}

async function migrate(seed) {
  const now = new Date();
  const courseByCode = new Map();
  const courseById = new Map();

  for (const theme of seed.themes || []) {
    await upsert(Theme, { id: theme.id }, {
      id: theme.id,
      themeCode: theme.themeCode || theme.code,
      title: theme.title,
      description: theme.description,
      blueprintSharePct: theme.blueprintSharePct ?? 0,
      priorityRank: theme.priorityRank ?? 1,
      customAttributes: theme.customAttributes || {},
    }, now);
  }

  const courseRows = seed.courses || defaultCourses.map(([id, themeId, code, title, examWeightPct, priorityLevel]) => ({
    id, themeId, code, title, creditHours: 3, examWeightPct, priorityLevel,
  }));
  for (const rawCourse of courseRows) {
    const course = normalizeCourse(rawCourse);
    if (!course.id || !course.courseCode) throw new Error('Every course needs id and courseCode/code');
    courseByCode.set(course.courseCode, course);
    courseById.set(course.id, course);
    await upsert(Course, { id: course.id }, course, now);
  }

  for (const chapter of seed.chapters || []) {
    await upsert(Chapter, { id: chapter.id }, {
      id: chapter.id,
      courseId: chapter.courseId,
      title: chapter.title,
      chapterNumber: chapter.chapterNumber ?? 1,
      sequenceOrder: chapter.sequenceOrder ?? chapter.chapterNumber ?? 1,
      priorityScore: chapter.priorityScore ?? 50,
      estMinutes: chapter.estMinutes ?? 60,
      customAttributes: chapter.customAttributes || {},
    }, now);
  }

  const questions = seed.questions || seed.samplePastExamQuestions || [];
  for (const rawQuestion of questions) {
    const question = normalizeQuestion(rawQuestion, courseByCode, courseById);
    if (!seed.chapters?.some((chapter) => chapter.id === question.chapterId)) {
      await upsert(Chapter, { id: question.chapterId }, {
        id: question.chapterId,
        courseId: question.courseId,
        title: `${question.course.title} Fundamentals`,
        chapterNumber: 1,
        sequenceOrder: 1,
        priorityScore: question.priorityWeight,
        estMinutes: 60,
        customAttributes: {},
      }, now);
    }
    await upsert(Question, { id: question.id }, {
      ...question,
      course: undefined,
    }, now);

    for (const option of rawQuestion.options || []) {
      const optionKey = option.optionKey || option.key;
      await upsert(QuestionOption, { optionId: option.optionId || `${question.id}_${optionKey}` }, {
        optionId: option.optionId || `${question.id}_${optionKey}`,
        questionId: question.id,
        optionKey,
        optionText: option.optionText || option.text,
        isCorrect: option.isCorrect === true,
        optionRationale: option.optionRationale || option.rationale || '',
      }, now);
    }
  }

  for (const material of seed.studyMaterials || seed.materials || []) {
    await upsert(StudyMaterial, { id: material.id }, {
      id: material.id,
      chapterId: material.chapterId,
      title: material.title,
      description: material.description,
      contentStyle: material.contentStyle || 'conceptNote',
      difficultyTier: material.difficultyTier ?? 1,
      priorityTier: material.priorityTier || 'P2_HIGH_YIELD',
      contentBlocks: material.contentBlocks || [],
      tags: material.tags || [],
      customAttributes: material.customAttributes || {},
    }, now);
  }

  for (const relation of seed.contentRelations || seed.relations || []) {
    await upsert(ContentRelation, { relationId: relation.relationId }, {
      relationId: relation.relationId,
      sourceType: relation.sourceType,
      sourceId: relation.sourceId,
      targetType: relation.targetType,
      targetId: relation.targetId,
      relationType: relation.relationType,
      relevanceWeight: relation.relevanceWeight ?? 1,
    }, now);
  }

  return {
    themes: (seed.themes || []).length,
    courses: courseRows.length,
    chapters: (seed.chapters || []).length || questions.length,
    questions: questions.length,
    materials: (seed.studyMaterials || seed.materials || []).length,
    relations: (seed.contentRelations || seed.relations || []).length,
  };
}

async function main() {
  if (!MONGODB_URI) throw new Error('MONGODB_URI or MONGO_URI is not set');
  const seed = JSON.parse(await fs.readFile(seedPath, 'utf8'));
  await mongoose.connect(MONGODB_URI);
  const counts = await migrate(seed);
  console.log('Curriculum migration completed:', counts);
  await mongoose.disconnect();
}

main().catch(async (error) => {
  console.error('Curriculum migration failed:', error.message);
  await mongoose.disconnect();
  process.exitCode = 1;
});
