const test = require('node:test');
const assert = require('node:assert/strict');
const { makeChoices, questionFor } = require('../seed_questions');
const models = require('../src/models');

test('generates stable four-option topic questions from a study material', () => {
  const course = { id: 'C_TEST', courseCode: 'ITec9999' };
  const materials = [
    { id: 'M1', title: 'Routing Protocols', chapterId: 'CH1', contentBlocks: [{ type: 'text', text: 'Routing protocols exchange network reachability information between routers. They use metrics and rules to select paths.' }], customAttributes: {} },
    { id: 'M2', title: 'IP Addressing', chapterId: 'CH1', contentBlocks: [], customAttributes: {} },
    { id: 'M3', title: 'Network Security', chapterId: 'CH1', contentBlocks: [], customAttributes: {} },
    { id: 'M4', title: 'Wireless Networks', chapterId: 'CH1', contentBlocks: [], customAttributes: {} },
  ];

  const first = questionFor(course, materials[0], materials, materials);
  const again = questionFor(course, materials[0], materials, materials);
  assert.equal(first.question.id, again.question.id);
  assert.equal(first.options.length, 4);
  assert.equal(first.options.filter((option) => option.isCorrect).length, 1);
  assert.equal(first.options.find((option) => option.isCorrect).optionText, 'Routing Protocols');
  assert.ok(first.question.stemBody.includes('Routing protocols exchange'));
});

test('declares unique MongoDB indexes for curriculum identifiers', () => {
  for (const modelName of ['Course', 'Chapter', 'StudyMaterial', 'Question']) {
    const indexes = models[modelName].schema.indexes();
    assert.ok(indexes.some(([keys, options]) => keys.id === 1 && options.unique));
  }
  assert.ok(models.Course.schema.indexes().some(([keys, options]) => keys.courseCode === 1 && options.unique));
});
