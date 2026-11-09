# EthioIT ExitPrep — Project Goals

Deliver an **offline‑first, adaptive mobile learning and mock‑exam platform** that readies fourth‑year BSc Information Technology students in Ethiopia for the FDRE National Exit Exam by providing blueprint‑aligned content, realistic timed simulations, linked concept‑to‑question flows, and actionable readiness analytics.

## 1. Full blueprint alignment
- Map all study modules, practice questions, and mock exams to the FDRE National Exit Exam Blueprint covering the 5 core themes and 13 selected IT courses (45 credit hours).
- **Acceptance**: 100% of learning items tagged to blueprint competencies and weightings.

## 2. Offline‑first availability
- Ensure core learning, bookmarking, practice questions, and analytics work fully offline using local storage.
- **Acceptance**: All essential features usable without connectivity; sync occurs when online.

## 3. Accurate timed mock‑exam simulator
- Provide topic quizzes and full‑length timed mock exams that mirror national exam format, with instant scoring and step‑by‑step rationales.
- **Acceptance**: Mock exam structure and timing configurable to reflect official exam parameters.

## 4. Multi‑dimensional content retrieval
- Enable fast filtering and retrieval of study items and questions by course, chapter, exam year, difficulty (simplicity/hardness), and priority.
- **Acceptance**: Users can combine at least three retrieval dimensions in a single query.

## 5. Linked concept‑to‑question navigation
- Implement bidirectional links so students can jump from a concept to related practice questions and from questions back to the underlying concept notes and rationales.
- **Acceptance**: Every question includes links to one or more related concept pages; concept pages list related questions.

## 6. Adaptive practice and prioritized sequencing
- Use performance, question difficulty, and blueprint weightings to create personalized practice queues that prioritize weak competencies and high‑weight topics.
- **Acceptance**: System reprioritizes practice sets based on latest user performance within two sessions.

## 7. Competency & readiness analytics
- Provide per‑topic mastery, exam‑readiness score, time‑on‑task, trend lines, and instructor‑ready reports to guide targeted revision.
- **Acceptance**: Dashboard shows mastery % by course, readiness score, and 30/90‑day performance trend.

## 8. Optimized UX for low‑end devices and local context
- Design a lightweight, simple interface in local languages with accessibility considerations and minimal bandwidth/CPU demands (Flutter/Android‑optimized).
- **Acceptance**: App runs smoothly on target low‑end Android devices and supports primary local languages.

## 9. Secure, privacy‑first data handling
- Store user progress on‑device by default, provide explicit consent for sync, and follow privacy best practices for any telemetry (anonymized by default).
- **Acceptance**: No automatic cloud upload of sensitive progress data; explicit opt‑in required.

## 10. Content maintainability and modular updates
- Architect content packages so new modules, past exam items, and blueprint updates can be published incrementally without full re‑downloads.
- **Acceptance**: Support delta updates for content with backward‑compatible tagging.

## 11. Scalability & cross‑platform readiness
- Build on Flutter with modular code and clean APIs so the app can scale to cohorts and platform targets while keeping performance predictable.
- **Acceptance**: Codebase supports easy addition of new courses and future cross‑platform builds.

## 12. Measured impact and continuous improvement
- Define and track success metrics (adoption among target cohort, improvement in readiness scores, mock‑to‑exam performance uplift) and instrument anonymized analytics for iteration.
- **Acceptance**: Baseline metrics instrumented and reports available for monthly review.

**Prioritization for MVP**: Focus on goals 1–4 and 7–9 in the initial release to ensure immediate exam relevance, offline reliability, and actionable feedback for students.
