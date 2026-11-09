const test = require('node:test');
const assert = require('node:assert/strict');
const { chapterGroupFor, makeBlocks, parseCourseFolder } = require('../ingest_courses');

test('parses course code and title from an organized course folder name', () => {
  assert.deepEqual(parseCourseFolder('08_ITec4133_Information_Assurance_and_Security'), {
    courseCode: 'ITec4133',
    title: 'Information Assurance and Security',
  });
  assert.equal(parseCourseFolder('projects'), null);
});

test('converts extracted text to reader-compatible content blocks', () => {
  assert.deepEqual(makeBlocks('# Overview\n\nA course paragraph.\n\n- First point'), [
    { type: 'heading', text: 'Overview' },
    { type: 'text', text: 'A course paragraph.' },
    { type: 'bullet', text: 'First point' },
  ]);
});

test('groups files by chapter number, parent folder, or general materials', () => {
  assert.deepEqual(chapterGroupFor('notes/Chapter_4_Routing.pdf'), {
    key: 'number:4',
    title: 'Chapter 4',
    chapterNumber: 4,
  });
  assert.deepEqual(chapterGroupFor('slides/Week_1/notes.pdf'), {
    key: 'folder:week 1',
    title: 'Week 1',
    chapterNumber: null,
  });
  assert.deepEqual(chapterGroupFor('outline.pdf'), {
    key: 'general',
    title: 'General Course Materials',
    chapterNumber: null,
  });
});
