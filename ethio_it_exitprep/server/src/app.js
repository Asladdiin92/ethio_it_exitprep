// server/src/app.js
// Express Delta-Sync REST API Application for EthioIT ExitPrep.

const express = require('express');
const cors = require('cors');
const { StudyMaterial, Question, ExamAttempt } = require('./models');

const app = express();
app.use(cors());
app.use(express.json());

// ── Health Check ─────────────────────────────────────────────────────────────
app.get('/api/v1/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'EthioIT ExitPrep Delta-Sync API',
    institution: 'Haramaya University Department of Information Technology',
    timestamp: new Date().toISOString(),
  });
});

// ── Delta-Pull: GET /api/v1/sync/pull?since=ISO8601 ─────────────────────────
app.get('/api/v1/sync/pull', async (req, res) => {
  try {
    const since = req.query.since ? new Date(req.query.since) : new Date(0);
    const serverTimestamp = new Date();

    // Query items updated after the watermark
    const updatedMaterials = await StudyMaterial.find({ updatedAt: { $gt: since } }).lean();
    const updatedQuestions = await Question.find({ updatedAt: { $gt: since } }).lean();

    res.json({
      serverTimestamp: serverTimestamp.toISOString(),
      updatedMaterials,
      updatedQuestions,
      deletedIds: [],
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── Outbox-Push: POST /api/v1/sync/push ───────────────────────────────────────
app.post('/api/v1/sync/push', async (req, res) => {
  try {
    const { mutations } = req.body;
    if (!Array.isArray(mutations)) {
      return res.status(400).json({ error: 'Expected mutations array' });
    }

    const results = [];
    for (const m of mutations) {
      if (m.entityType === 'exam_attempt') {
        const attempt = await ExamAttempt.findOneAndUpdate(
          { attemptId: m.attemptId },
          {
            attemptId: m.attemptId,
            studentId: m.studentId,
            startedAt: new Date(m.startedAt || Date.now()),
            completedAt: m.completedAt ? new Date(m.completedAt) : null,
            totalQuestions: m.totalQuestions,
            correctAnswers: m.correctAnswers,
            scorePercent: m.scorePercent,
            answerMap: m.answerMap || {},
          },
          { upsert: true, new: true }
        );
        results.push({ attemptId: m.attemptId, status: 'synced' });
      }
    }

    res.json({
      status: 'success',
      syncedCount: results.length,
      results,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = app;
