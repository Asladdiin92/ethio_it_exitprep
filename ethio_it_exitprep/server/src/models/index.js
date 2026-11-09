// server/src/models/index.js
// Mongoose Models for MongoDB Atlas Delta-Sync API mirroring the 8 canonical entities.

const mongoose = require('mongoose');

// 1. ProgramTheme
const ThemeSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  themeCode: { type: String, required: true },
  title: { type: String, required: true },
  description: String,
  blueprintSharePct: { type: Number, default: 0.0 },
  priorityRank: { type: Number, default: 1 },
  customAttributes: { type: mongoose.Schema.Types.Mixed, default: {} },
}, { timestamps: true });

// 2. Course
const CourseSchema = new mongoose.Schema({
  id: { type: String, required: true },
  themeId: { type: String, required: true },
  courseCode: { type: String, required: true },
  title: { type: String, required: true },
  description: String,
  courseYear: { type: Number, default: 1, min: 1 },
  semester: { type: Number, default: 1, min: 1, max: 2 },
  creditHours: { type: Number, default: 3 },
  examWeightPct: { type: Number, default: 0.0 },
  priorityLevel: { type: String, default: 'P2' },
  customAttributes: { type: mongoose.Schema.Types.Mixed, default: {} },
}, { timestamps: true });
CourseSchema.index({ id: 1 }, { unique: true });
CourseSchema.index({ courseCode: 1 }, { unique: true });

// 3. Chapter
const ChapterSchema = new mongoose.Schema({
  id: { type: String, required: true },
  courseId: { type: String, required: true },
  title: { type: String, required: true },
  chapterNumber: { type: Number, required: true },
  sequenceOrder: { type: Number, required: true },
  priorityScore: { type: Number, default: 50.0 },
  estMinutes: { type: Number, default: 60 },
  customAttributes: { type: mongoose.Schema.Types.Mixed, default: {} },
}, { timestamps: true });
ChapterSchema.index({ id: 1 }, { unique: true });

// 4. StudyMaterial
const StudyMaterialSchema = new mongoose.Schema({
  id: { type: String, required: true },
  chapterId: { type: String, required: true },
  title: { type: String, required: true },
  description: String,
  contentStyle: { type: String, required: true },
  difficultyTier: { type: Number, default: 1 },
  priorityTier: { type: String, default: 'P2_HIGH_YIELD' },
  contentBlocks: { type: Array, default: [] },
  tags: { type: [String], default: [] },
  customAttributes: { type: mongoose.Schema.Types.Mixed, default: {} },
}, { timestamps: true });
StudyMaterialSchema.index({ id: 1 }, { unique: true });

// 5. ContentRelation
const ContentRelationSchema = new mongoose.Schema({
  relationId: { type: String, required: true, unique: true },
  sourceType: { type: String, required: true },
  sourceId: { type: String, required: true },
  targetType: { type: String, required: true },
  targetId: { type: String, required: true },
  relationType: { type: String, required: true },
  relevanceWeight: { type: Number, default: 1.0 },
}, { timestamps: true });

// 6. Question
const QuestionSchema = new mongoose.Schema({
  id: { type: String, required: true },
  courseId: { type: String, required: true },
  chapterId: { type: String, required: true },
  linkedMaterialId: String,
  title: { type: String, required: true },
  description: String,
  examYear: { type: Number, required: true },
  sourceType: { type: String, required: true },
  difficultyTier: { type: Number, default: 1 },
  priorityWeight: { type: Number, default: 50.0 },
  bloomDomain: { type: String, default: 'cognitive' },
  stemTitle: { type: String, required: true },
  stemBody: { type: String, required: true },
  generalExplanation: { type: String, required: true },
  customAttributes: { type: mongoose.Schema.Types.Mixed, default: {} },
}, { timestamps: true });
QuestionSchema.index({ id: 1 }, { unique: true });

// 7. QuestionOption
const QuestionOptionSchema = new mongoose.Schema({
  optionId: { type: String, required: true, unique: true },
  questionId: { type: String, required: true },
  optionKey: { type: String, required: true },
  optionText: { type: String, required: true },
  isCorrect: { type: Boolean, default: false },
  optionRationale: { type: String, required: true },
}, { timestamps: true });

// 8. StudentProgress & ExamAttempt
const ExamAttemptSchema = new mongoose.Schema({
  attemptId: { type: String, required: true, unique: true },
  studentId: { type: String, required: true },
  startedAt: { type: Date, required: true },
  completedAt: Date,
  totalQuestions: { type: Number, required: true },
  correctAnswers: { type: Number, required: true },
  scorePercent: { type: Number, required: true },
  answerMap: { type: mongoose.Schema.Types.Mixed, default: {} },
}, { timestamps: true });

const DeletedEntitySchema = new mongoose.Schema({
  entityType: { type: String, enum: ['material', 'question'], required: true },
  entityId: { type: String, required: true },
  deletedAt: { type: Date, required: true, default: Date.now },
}, { timestamps: false });

DeletedEntitySchema.index({ deletedAt: 1 });

module.exports = {
  Theme: mongoose.model('ProgramTheme', ThemeSchema),
  Course: mongoose.model('Course', CourseSchema),
  Chapter: mongoose.model('Chapter', ChapterSchema),
  StudyMaterial: mongoose.model('StudyMaterial', StudyMaterialSchema),
  ContentRelation: mongoose.model('ContentRelation', ContentRelationSchema),
  Question: mongoose.model('Question', QuestionSchema),
  QuestionOption: mongoose.model('QuestionOption', QuestionOptionSchema),
  ExamAttempt: mongoose.model('ExamAttempt', ExamAttemptSchema),
  DeletedEntity: mongoose.model('DeletedEntity', DeletedEntitySchema),
};
