require('dotenv').config({ path: require('node:path').join(__dirname, '.env') });

const crypto = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');
const { promisify } = require('node:util');
const { execFile } = require('node:child_process');
const mongoose = require('mongoose');
const {
  Theme,
  Course,
  Chapter,
  StudyMaterial,
  Question,
} = require('./src/models');

const execFileAsync = promisify(execFile);
const SOURCE_ROOT = path.resolve(__dirname, '../../../../..');
const REPOSITORY_ROOT = path.resolve(__dirname, '../..');
const COURSE_FOLDER_PATTERN = /^0[1-8]_(ITec\d+)_(.+)$/i;
const SUPPORTED_EXTENSIONS = new Set(['.pdf', '.doc', '.docx', '.pptx', '.md', '.txt', '.rtf']);
const MAX_EXTRACTED_BYTES = 6 * 1024 * 1024;
const TOOL_MAX_BUFFER = 32 * 1024 * 1024;
const SOURCE_THEME_ID = 'SOURCE_COURSE_MATERIALS';

function parseCourseFolder(folderName) {
  const match = COURSE_FOLDER_PATTERN.exec(folderName);
  if (!match) return null;

  return {
    courseCode: match[1],
    title: match[2].replace(/[_-]+/g, ' ').replace(/\s+/g, ' ').trim(),
  };
}

function chapterGroupFor(relativePath) {
  const fileName = path.basename(relativePath, path.extname(relativePath));
  const numberMatch = /(?:^|[\s_.-])(?:chapter|ch|lecture|lec|unit|module)[\s_.-]*(\d+)(?!\d)/i.exec(fileName)
    || /^(\d+)(?:[_.-]\d+)*\b/.exec(fileName);
  if (numberMatch) {
    const number = Number(numberMatch[1]);
    return { key: `number:${number}`, title: `Chapter ${number}`, chapterNumber: number };
  }

  const parentName = path.basename(path.dirname(relativePath));
  if (parentName !== '.') {
    const title = parentName.replace(/[_-]+/g, ' ').replace(/\s+/g, ' ').trim();
    return { key: `folder:${title.toLowerCase()}`, title, chapterNumber: null };
  }

  return { key: 'general', title: 'General Course Materials', chapterNumber: null };
}

function makeBlocks(text) {
  const blocks = [];
  let paragraph = [];

  function flushParagraph() {
    const value = paragraph.join(' ').trim();
    paragraph = [];
    if (!value) return;

    let remaining = value;
    while (remaining.length > 3500) {
      let splitAt = remaining.lastIndexOf(' ', 3500);
      if (splitAt < 1000) splitAt = 3500;
      blocks.push({ type: 'text', text: remaining.slice(0, splitAt).trim() });
      remaining = remaining.slice(splitAt).trim();
    }
    if (remaining) blocks.push({ type: 'text', text: remaining });
  }

  for (const rawLine of text.replace(/\r\n?/g, '\n').split('\n')) {
    const line = rawLine.trim();
    if (!line) {
      flushParagraph();
      continue;
    }

    const heading = /^#{1,6}\s+(.+)$/.exec(line);
    if (heading) {
      flushParagraph();
      blocks.push({ type: 'heading', text: heading[1].trim() });
      continue;
    }

    const bullet = /^(?:[-*+]|\d+[.)])\s+(.+)$/.exec(line);
    if (bullet) {
      flushParagraph();
      blocks.push({ type: 'bullet', text: bullet[1].trim() });
      continue;
    }

    paragraph.push(line);
  }
  flushParagraph();
  return blocks;
}

function decodeXmlText(xml) {
  return xml
    .replace(/<w:tab\b[^>]*\/>/g, '\t')
    .replace(/<\/w:p>/g, '\n\n')
    .replace(/<\/a:p>/g, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&#(\d+);/g, (_, code) => String.fromCodePoint(Number(code)))
    .replace(/&#x([0-9a-f]+);/gi, (_, code) => String.fromCodePoint(parseInt(code, 16)));
}

function shouldSkipPath(filePath) {
  const absolutePath = path.resolve(filePath);
  if (absolutePath === REPOSITORY_ROOT || absolutePath.startsWith(`${REPOSITORY_ROOT}${path.sep}`)) {
    return true;
  }

  const parts = absolutePath.slice(SOURCE_ROOT.length).split(path.sep);
  return parts.some((part) =>
    part.startsWith('.') ||
    ['node_modules', 'build', 'my_test_folder'].includes(part.toLowerCase()) ||
    part.toLowerCase() === 'student_grades_db.txt',
  );
}

async function findCourseFiles(directory) {
  const found = [];

  async function walk(current) {
    if (shouldSkipPath(current)) return;
    const entries = await fs.readdir(current, { withFileTypes: true });
    entries.sort((a, b) => a.name.localeCompare(b.name));

    for (const entry of entries) {
      const fullPath = path.join(current, entry.name);
      if (shouldSkipPath(fullPath) || entry.isSymbolicLink()) continue;
      if (entry.isDirectory()) {
        await walk(fullPath);
      } else if (entry.isFile() && SUPPORTED_EXTENSIONS.has(path.extname(entry.name).toLowerCase())) {
        found.push(fullPath);
      }
    }
  }

  await walk(directory);
  return found;
}

async function runTool(command, args) {
  const { stdout } = await execFileAsync(command, args, {
    encoding: 'utf8',
    maxBuffer: TOOL_MAX_BUFFER,
  });
  return stdout;
}

async function extractText(filePath) {
  const extension = path.extname(filePath).toLowerCase();
  if (extension === '.pdf') {
    return runTool('pdftotext', ['-enc', 'UTF-8', '-layout', filePath, '-']);
  }
  if (extension === '.doc') {
    return runTool('antiword', [filePath]);
  }
  if (extension === '.docx') {
    const xml = await runTool('unzip', ['-p', filePath, 'word/document.xml']);
    return decodeXmlText(xml);
  }
  if (extension === '.pptx') {
    const listing = await runTool('unzip', ['-Z1', filePath]);
    const slides = listing
      .split('\n')
      .filter((name) => /^ppt\/slides\/slide\d+\.xml$/.test(name))
      .sort((a, b) => Number(a.match(/slide(\d+)/)[1]) - Number(b.match(/slide(\d+)/)[1]));
    const texts = [];
    for (const slide of slides) {
      texts.push(decodeXmlText(await runTool('unzip', ['-p', filePath, slide])));
    }
    return texts.join('\n\n');
  }
  if (extension === '.rtf') {
    return runTool('pandoc', ['-f', 'rtf', '-t', 'plain', filePath]);
  }
  return fs.readFile(filePath, 'utf8');
}

async function collectMaterials(courseDirectory, courseCode) {
  const files = await findCourseFiles(courseDirectory);
  const materials = [];
  let emptyTextFiles = 0;

  for (const filePath of files) {
    const text = (await extractText(filePath)).replace(/\u0000/g, '').trim();
    if (!text) {
      emptyTextFiles += 1;
      continue;
    }
    if (Buffer.byteLength(text, 'utf8') > MAX_EXTRACTED_BYTES) {
      throw new Error(`Extracted text exceeds 6 MiB: ${path.relative(SOURCE_ROOT, filePath)}`);
    }

    const relativePath = path.relative(courseDirectory, filePath).split(path.sep).join('/');
    const extension = path.extname(filePath).slice(1).toLowerCase();
    const idHash = crypto.createHash('sha256').update(`${courseCode}\0${relativePath}`).digest('hex');
    const contentHash = crypto.createHash('sha256').update(text).digest('hex');
    const chapterGroup = chapterGroupFor(relativePath);
    const contentBlocks = makeBlocks(text);
    if (!contentBlocks.length) {
      emptyTextFiles += 1;
      continue;
    }

    materials.push({
      id: `SRC_MAT_${idHash}`,
      title: path.basename(filePath, path.extname(filePath)).replace(/[_-]+/g, ' ').trim(),
      description: `Extracted from ${relativePath} (${extension.toUpperCase()})`,
      contentStyle: 'conceptNote',
      difficultyTier: 1,
      priorityTier: 'P2_HIGH_YIELD',
      contentBlocks,
      tags: ['source:course-folder', `course:${courseCode}`, `file:${extension}`],
      customAttributes: {
        sourcePath: relativePath,
        sourceFileType: extension,
        sourceContentSha256: contentHash,
        sourceChapterKey: chapterGroup.key,
      },
      chapterGroup,
    });
  }

  return { filesScanned: files.length, emptyTextFiles, materials };
}

async function upsertById(Model, document, now) {
  await Model.updateOne(
    { id: document.id },
    { $set: { ...document, updatedAt: now }, $setOnInsert: { createdAt: now } },
    { upsert: true, runValidators: true },
  );
}

async function bulkUpsertById(Model, documents, now) {
  const batchSize = 250;
  for (let offset = 0; offset < documents.length; offset += batchSize) {
    const batch = documents.slice(offset, offset + batchSize);
    await Model.bulkWrite(batch.map((document) => ({
      updateOne: {
        filter: { id: document.id },
        update: {
          $set: { ...document, updatedAt: now },
          $setOnInsert: { createdAt: now },
        },
        upsert: true,
      },
    })), { ordered: false });
  }
}

async function upsertCourse(course, now) {
  const existing = await Course.find({ courseCode: course.courseCode }).select('id').lean();
  if (existing.length > 1) {
    throw new Error(`Multiple existing courses use code ${course.courseCode}; resolve them before ingestion`);
  }

  const id = existing[0]?.id || `SRC_COURSE_${course.courseCode.toUpperCase()}`;
  await Course.updateOne(
    { courseCode: course.courseCode },
    {
      $set: {
        courseCode: course.courseCode,
        title: course.title,
        description: `Imported from the ${course.courseCode} course folder.`,
        updatedAt: now,
      },
      $setOnInsert: {
        id,
        themeId: SOURCE_THEME_ID,
        courseYear: 1,
        semester: 1,
        creditHours: 3,
        examWeightPct: 0,
        priorityLevel: 'P2',
        customAttributes: { source: 'course-folder-ingestion' },
        createdAt: now,
      },
    },
    { upsert: true, runValidators: true },
  );

  return id;
}

async function seedCourse(course, now) {
  const courseId = await upsertCourse(course, now);
  const groups = new Map();
  for (const material of course.materials) {
    const group = groups.get(material.chapterGroup.key) || {
      ...material.chapterGroup,
      materials: [],
    };
    group.materials.push(material);
    groups.set(material.chapterGroup.key, group);
  }

  const sortedGroups = [...groups.values()].sort((a, b) => {
    if (a.chapterNumber !== null && b.chapterNumber !== null) return a.chapterNumber - b.chapterNumber;
    if (a.chapterNumber !== null) return -1;
    if (b.chapterNumber !== null) return 1;
    return a.title.localeCompare(b.title);
  });
  const activeChapterIds = [];
  const materialDocuments = [];
  for (const [index, group] of sortedGroups.entries()) {
    const groupHash = crypto.createHash('sha256').update(group.key).digest('hex').slice(0, 16);
    const chapterId = `SRC_CH_${course.courseCode.toUpperCase()}_${groupHash}`;
    activeChapterIds.push(chapterId);
    await upsertById(Chapter, {
      id: chapterId,
      courseId,
      title: group.title,
      chapterNumber: group.chapterNumber ?? index + 1,
      sequenceOrder: index + 1,
      priorityScore: 50,
      estMinutes: 60,
      customAttributes: {
        source: 'course-folder-ingestion',
        sourceChapterKey: group.key,
      },
    }, now);

    for (const material of group.materials) {
      const { chapterGroup, ...document } = material;
      materialDocuments.push({ ...document, chapterId });
    }
  }
  await bulkUpsertById(StudyMaterial, materialDocuments, now);

  const staleChapters = await Chapter.find({
    courseId,
    'customAttributes.source': 'course-folder-ingestion',
    id: { $nin: activeChapterIds },
  }).select('id').lean();
  for (const chapter of staleChapters) {
    const [materialCount, questionCount] = await Promise.all([
      StudyMaterial.countDocuments({ chapterId: chapter.id }),
      Question.countDocuments({ chapterId: chapter.id }),
    ]);
    if (materialCount === 0 && questionCount === 0) {
      await Chapter.deleteOne({ id: chapter.id });
    }
  }

  const legacyChapterId = `SRC_CH_${course.courseCode.toUpperCase()}`;
  const [legacyMaterialCount, legacyQuestionCount] = await Promise.all([
    StudyMaterial.countDocuments({ chapterId: legacyChapterId }),
    Question.countDocuments({ chapterId: legacyChapterId }),
  ]);
  if (legacyMaterialCount === 0 && legacyQuestionCount === 0) {
    await Chapter.deleteOne({ id: legacyChapterId, courseId });
  }

  const [courseCount, chapterCount, materialCount, questionCount] = await Promise.all([
    Course.countDocuments({ courseCode: course.courseCode }),
    Chapter.countDocuments({ courseId }),
    StudyMaterial.countDocuments({ chapterId: { $in: activeChapterIds } }),
    Question.countDocuments({ courseId }),
  ]);
  return {
    courseCode: course.courseCode,
    title: course.title,
    courseId,
    coursesInDatabase: courseCount,
    chaptersInDatabase: chapterCount,
    filesScanned: course.filesScanned,
    emptyTextFiles: course.emptyTextFiles,
    materialsUpserted: course.materials.length,
    materialsInDatabase: materialCount,
    questionsInDatabase: questionCount,
  };
}

async function loadCourses() {
  const entries = await fs.readdir(SOURCE_ROOT, { withFileTypes: true });
  const folders = entries
    .filter((entry) => entry.isDirectory() && parseCourseFolder(entry.name))
    .sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true }));

  if (folders.length !== 8 || folders.some((entry, index) => !entry.name.startsWith(`${String(index + 1).padStart(2, '0')}_`))) {
    throw new Error(`Expected course directories 01 through 08 in ${SOURCE_ROOT}; found ${folders.length}`);
  }

  const courses = [];
  for (const folder of folders) {
    const parsed = parseCourseFolder(folder.name);
    const collected = await collectMaterials(path.join(SOURCE_ROOT, folder.name), parsed.courseCode);
    courses.push({ ...parsed, ...collected });
  }
  return courses;
}

async function main() {
  const dryRun = process.argv.includes('--dry-run');
  const unknownArguments = process.argv.slice(2).filter((arg) => arg !== '--dry-run');
  if (unknownArguments.length) throw new Error(`Unknown argument: ${unknownArguments[0]}`);

  const courses = await loadCourses();
  const sourceSummary = courses.map(({ courseCode, title, filesScanned, emptyTextFiles, materials }) => ({
    courseCode,
    title,
    filesScanned,
    emptyTextFiles,
    extractedMaterials: materials.length,
  }));
  if (dryRun) {
    console.log(JSON.stringify({ dryRun: true, courses: sourceSummary }, null, 2));
    return;
  }

  const mongoUri = process.env.MONGODB_URI || process.env.MONGO_URI;
  if (!mongoUri) throw new Error('MONGODB_URI or MONGO_URI is not set in server/.env');

  await mongoose.connect(mongoUri);
  try {
    const now = new Date();
    await upsertById(Theme, {
      id: SOURCE_THEME_ID,
      themeCode: 'SOURCE_MATERIALS',
      title: 'Imported Course Materials',
      description: 'Study materials imported from the organized course folders.',
      blueprintSharePct: 0,
      priorityRank: 1,
      customAttributes: { source: 'course-folder-ingestion' },
    }, now);

    const results = [];
    for (const course of courses) {
      results.push(await seedCourse(course, now));
    }
    console.log(JSON.stringify({ seededAt: now.toISOString(), courses: results }, null, 2));
  } finally {
    await mongoose.disconnect();
  }
}

module.exports = { chapterGroupFor, makeBlocks, parseCourseFolder };

if (require.main === module) {
  main().catch(async (error) => {
    console.error(`Course ingestion failed: ${error.message}`);
    if (mongoose.connection.readyState !== 0) await mongoose.disconnect();
    process.exitCode = 1;
  });
}
