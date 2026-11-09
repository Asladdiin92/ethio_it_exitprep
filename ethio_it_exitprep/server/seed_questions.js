require('dotenv').config({ path: require('node:path').join(__dirname, '.env') });

const crypto = require('node:crypto');
const mongoose = require('mongoose');
const {
  Course,
  Chapter,
  StudyMaterial,
  Question,
  QuestionOption,
} = require('./src/models');

function hash(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function passageFor(material) {
  const blocks = Array.isArray(material.contentBlocks) ? material.contentBlocks : [];
  const candidates = blocks
    .map((block) => String(block?.text || '').replace(/\s+/g, ' ').trim())
    .filter((text) => text.length >= 60);
  if (!candidates.length) return material.description || material.title;
  const index = Number.parseInt(hash(material.id).slice(0, 8), 16) % candidates.length;
  const passage = candidates[index];
  return passage.length > 1200 ? `${passage.slice(0, 1197).trimEnd()}...` : passage;
}

function makeChoices(material, sameCourseMaterials, allMaterials) {
  const correctTitle = material.title.trim();
  const normalize = (items) => [...new Set(items.map((title) => title.trim()))]
    .filter((title) => title && title.toLocaleLowerCase() !== correctTitle.toLocaleLowerCase())
    .sort((a, b) => hash(`${material.id}:${a}`).localeCompare(hash(`${material.id}:${b}`)));
  const localTopics = normalize(sameCourseMaterials.map((item) => item.title));
  const curriculumTopics = normalize(allMaterials.map((item) => item.title));
  const uniqueDistractors = [...localTopics, ...curriculumTopics.filter((topic) => !localTopics.includes(topic))];
  if (uniqueDistractors.length < 3) {
    throw new Error(`Not enough distinct distractor topics for material ${material.id}`);
  }

  const distractors = uniqueDistractors.slice(0, 3);
  const choices = [
    { optionText: correctTitle, isCorrect: true },
    ...distractors.map((optionText) => ({ optionText, isCorrect: false })),
  ];
  const seed = hash(material.id);
  for (let index = choices.length - 1; index > 0; index -= 1) {
    const offset = Number.parseInt(seed.slice(index * 2, index * 2 + 2), 16) % (index + 1);
    [choices[index], choices[offset]] = [choices[offset], choices[index]];
  }
  return choices.map((choice, index) => ({
    optionId: `${material.id}_TOPIC_V1_${String.fromCharCode(65 + index)}`,
    optionKey: String.fromCharCode(65 + index),
    ...choice,
    optionRationale: choice.isCorrect
      ? `The excerpt is taken from the study material "${correctTitle}".`
      : `This is a different topic; the excerpt is from "${correctTitle}".`,
  }));
}

function questionFor(course, material, sameCourseMaterials, allMaterials) {
  const questionId = `SRC_Q_${hash(`${material.id}:topic-mcq-v1`)}`;
  const options = makeChoices(material, sameCourseMaterials, allMaterials);
  return {
    question: {
      id: questionId,
      courseId: course.id,
      chapterId: material.chapterId,
      linkedMaterialId: material.id,
      title: `Study topic identification: ${course.courseCode}`,
      description: `Practice question generated from ${material.customAttributes?.sourcePath || material.title}.`,
      examYear: 2018,
      sourceType: 'COURSE_DRILL',
      difficultyTier: 2,
      priorityWeight: 60,
      bloomDomain: 'cognitive',
      stemTitle: 'Identify the topic from its excerpt',
      stemBody: `Which study topic is most directly represented by this excerpt?\n\n${passageFor(material)}`,
      generalExplanation: `This question is linked to "${material.title}". The excerpt was extracted from ${material.customAttributes?.sourcePath || 'the source study material'}.`,
      customAttributes: {
        generator: 'study-material-topic-mcq',
        generatorVersion: 1,
      },
    },
    options: options.map((option) => ({
      ...option,
      questionId,
    })),
  };
}

async function bulkUpsert(Model, documents, key, now) {
  const batchSize = 250;
  for (let offset = 0; offset < documents.length; offset += batchSize) {
    const batch = documents.slice(offset, offset + batchSize);
    await Model.bulkWrite(batch.map((document) => ({
      updateOne: {
        filter: { [key]: document[key] },
        update: {
          $set: { ...document, updatedAt: now },
          $setOnInsert: { createdAt: now },
        },
        upsert: true,
      },
    })), { ordered: false });
  }
}

async function seedQuestions() {
  const courses = await Course.find({ customAttributes: { $exists: true } }).lean();
  const courseCodes = [
    'ITec4121', 'ITec4151', 'ITec4153', 'ITec4103',
    'ITec4155', 'ITec4111', 'ITec4131', 'ITec4133',
  ];
  const selectedCourses = courses.filter((course) => courseCodes.includes(course.courseCode));
  if (selectedCourses.length !== courseCodes.length) {
    throw new Error(`Expected all 8 ingested courses; found ${selectedCourses.length}`);
  }

  const courseMaterials = new Map();
  const allMaterials = [];
  for (const course of selectedCourses) {
    const chapters = await Chapter.find({ courseId: course.id }).select('id').lean();
    const chapterIds = chapters.map((chapter) => chapter.id);
    const materials = await StudyMaterial.find({ chapterId: { $in: chapterIds } }).lean();
    courseMaterials.set(course.id, materials);
    allMaterials.push(...materials);
  }
  if (!allMaterials.length) throw new Error('No ingested study materials found');

  const now = new Date();
  const questionDocuments = [];
  const optionDocuments = [];
  const generatedByCourse = new Map();
  for (const course of selectedCourses) {
    const materials = courseMaterials.get(course.id);
    const questionIds = [];
    for (const material of materials) {
      const { question, options } = questionFor(course, material, materials, allMaterials);
      questionDocuments.push(question);
      optionDocuments.push(...options);
      questionIds.push(question.id);
    }
    generatedByCourse.set(course.id, questionIds);
  }
  await bulkUpsert(Question, questionDocuments, 'id', now);
  await bulkUpsert(QuestionOption, optionDocuments, 'optionId', now);

  const counts = [];
  for (const course of selectedCourses) {
    const questionIds = generatedByCourse.get(course.id);
    const [questionCount, optionCount] = await Promise.all([
      Question.countDocuments({ courseId: course.id }),
      QuestionOption.countDocuments({
        questionId: { $in: questionIds },
      }),
    ]);
    counts.push({
      courseCode: course.courseCode,
      courseId: course.id,
      questionsUpserted: questionIds.length,
      questionsInDatabase: questionCount,
      optionsInDatabase: optionCount,
    });
  }
  return counts;
}

async function main() {
  const mongoUri = process.env.MONGODB_URI || process.env.MONGO_URI;
  if (!mongoUri) throw new Error('MONGODB_URI or MONGO_URI is not set in server/.env');

  await mongoose.connect(mongoUri);
  try {
    console.log(JSON.stringify({ seededAt: new Date().toISOString(), courses: await seedQuestions() }, null, 2));
  } finally {
    await mongoose.disconnect();
  }
}

module.exports = { makeChoices, passageFor, questionFor };

if (require.main === module) {
  main().catch(async (error) => {
    console.error(`Question seeding failed: ${error.message}`);
    if (mongoose.connection.readyState !== 0) await mongoose.disconnect();
    process.exitCode = 1;
  });
}
