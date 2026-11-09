if (process.env.NODE_ENV === 'production') {
  throw new Error('The local development server cannot run with NODE_ENV=production');
}

process.env.NODE_ENV = 'development';
process.env.SYNC_DEV_MODE = 'true';

require('./server').bootstrap();
