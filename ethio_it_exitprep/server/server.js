// server/server.js
// Node.js server entry point.

require('dotenv').config();
const mongoose = require('mongoose');
const app = require('./src/app');

const PORT = process.env.PORT || 4000;
const LOCAL_DEV_SYNC =
  process.env.NODE_ENV === 'development' && process.env.SYNC_DEV_MODE === 'true';
const HOST = LOCAL_DEV_SYNC ? '127.0.0.1' : (process.env.HOST || '0.0.0.0');
const MONGODB_URI = process.env.MONGODB_URI || process.env.MONGO_URI || 'mongodb://localhost:27017/ethio_it_exitprep';

async function bootstrap() {
  try {
    if (process.env.NODE_ENV !== 'test') {
      await mongoose.connect(MONGODB_URI);
      console.log('Connected to MongoDB Atlas / Local Database.');
    }
    app.listen(PORT, HOST, () => {
      console.log(`EthioIT ExitPrep Delta-Sync API listening on ${HOST}:${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error.message);
    process.exit(1);
  }
}

if (require.main === module) {
  bootstrap();
}

module.exports = app;
module.exports.bootstrap = bootstrap;
