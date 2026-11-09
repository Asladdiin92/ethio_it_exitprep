// server/src/app.js
// Express Delta-Sync REST API Application for EthioIT ExitPrep.

const express = require('express');
const cors = require('cors');
const crypto = require('node:crypto');
const { StudyMaterial, Question, ExamAttempt, DeletedEntity } = require('./models');

const app = express();
app.use(cors({ origin: process.env.CORS_ORIGIN || false }));
app.use(express.json({ limit: '256kb' }));

function authenticate(req, res, next) {
  const secret = process.env.SYNC_API_SECRET;
  const authorization = req.get('authorization') || '';
  const parts = authorization.startsWith('Bearer ') ? authorization.slice(7).split('.') : [];

  if (!secret || parts.length !== 3) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  try {
    const [encodedHeader, encodedPayload, encodedSignature] = parts;
    const header = JSON.parse(Buffer.from(encodedHeader, 'base64url').toString('utf8'));
    const payload = JSON.parse(Buffer.from(encodedPayload, 'base64url').toString('utf8'));
    const expectedSignature = crypto
      .createHmac('sha256', secret)
      .update(`${encodedHeader}.${encodedPayload}`)
      .digest();
    const actualSignature = Buffer.from(encodedSignature, 'base64url');

    if (header.alg !== 'HS256' || expectedSignature.length !== actualSignature.length ||
        !crypto.timingSafeEqual(expectedSignature, actualSignature) ||
        typeof payload.sub !== 'string' || (payload.exp && payload.exp <= Math.floor(Date.now() / 1000))) {
      return res.status(401).json({ error: 'Invalid authentication token' });
    }

    req.studentId = payload.sub;
    return next();
  } catch (_) {
    return res.status(401).json({ error: 'Invalid authentication token' });
  }
}

function isFiniteNumber(value) {
  return typeof value === 'number' && Number.isFinite(value);
}

function validateAttempt(mutation, studentId) {
  if (!mutation || mutation.entityType !== 'exam_attempt' || mutation.studentId !== studentId ||
      typeof mutation.attemptId !== 'string' || mutation.attemptId.length === 0 ||
      !Number.isInteger(mutation.totalQuestions) || mutation.totalQuestions <= 0 ||
      !Number.isInteger(mutation.correctAnswers) || mutation.correctAnswers < 0 ||
      mutation.correctAnswers > mutation.totalQuestions ||
      !isFiniteNumber(mutation.scorePercent) || mutation.scorePercent < 0 || mutation.scorePercent > 100 ||
      (mutation.startedAt !== undefined &&
        (typeof mutation.startedAt !== 'string' || Number.isNaN(Date.parse(mutation.startedAt)))) ||
      (mutation.completedAt !== undefined &&
        (mutation.completedAt !== null &&
          (typeof mutation.completedAt !== 'string' || Number.isNaN(Date.parse(mutation.completedAt))))) ||
      (mutation.answerMap !== undefined && (typeof mutation.answerMap !== 'object' || mutation.answerMap === null || Array.isArray(mutation.answerMap)))) {
    return 'Invalid exam attempt';
  }
  return null;
}

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
app.get('/api/v1/sync/pull', authenticate, async (req, res) => {
  try {
    const since = req.query.since ? new Date(req.query.since) : new Date(0);
    if (Number.isNaN(since.getTime())) {
      return res.status(400).json({ error: 'Invalid since timestamp' });
    }
    const serverTimestamp = new Date();

    // Query items updated after the watermark
    const updatedMaterials = await StudyMaterial.find({ updatedAt: { $gt: since } }).lean();
    const updatedQuestions = await Question.find({ updatedAt: { $gt: since } }).lean();
    const deletedEntities = await DeletedEntity.find({ deletedAt: { $gt: since } })
      .select({ _id: 0, entityType: 1, entityId: 1 })
      .lean();

    res.json({
      serverTimestamp: serverTimestamp.toISOString(),
      updatedMaterials,
      updatedQuestions,
      deletedEntities,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ── Outbox-Push: POST /api/v1/sync/push ───────────────────────────────────────
app.post('/api/v1/sync/push', authenticate, async (req, res) => {
  try {
    const { mutations } = req.body;
    if (!Array.isArray(mutations)) {
      return res.status(400).json({ error: 'Expected mutations array' });
    }

    const results = [];
    const rejected = [];
    for (const m of mutations) {
      if (m.entityType === 'exam_attempt') {
        const validationError = validateAttempt(m, req.studentId);
        if (validationError) {
          rejected.push({ attemptId: m.attemptId ?? null, error: validationError });
          continue;
        }
        await ExamAttempt.findOneAndUpdate(
          { attemptId: m.attemptId },
          {
            attemptId: m.attemptId,
            studentId: req.studentId,
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
      } else {
        rejected.push({ attemptId: null, error: 'Unsupported mutation type' });
      }
    }

    res.status(rejected.length === 0 ? 200 : 207).json({
      status: 'success',
      syncedCount: results.length,
      results,
      rejected,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = app;
