
const path = require('path');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
  ],
});

const envPath = path.resolve(__dirname, '..', '.env');
dotenv.config({ path: envPath });

const HealthMetric = require('../src/models/HealthMetric');

async function main() {
  const uri = process.env.MONGO_URI;
  if (!uri) {
    logger.error('❌ MONGO_URI is not set');
    process.exit(1);
  }

  logger.info('🔍 Connecting to MongoDB...');
  await mongoose.connect(uri);
  logger.info('✅ Connected');

  const demoUid = process.env.DEMO_UID || 'demo-shared';
  logger.info('[Testing queries with UID]');

  // Test 1: Count all documents for this UID
  const count = await HealthMetric.countDocuments({ userUid: demoUid });
  logger.info('Total documents for UID', { count });

  // Test 2: Get latest document
  const latest = await HealthMetric.findOne({ userUid: demoUid })
    .sort({ date: -1 })
    .lean();
  logger.info('Latest document date', { date: latest?.date });
  logger.info('Fields', { fields: latest ? Object.keys(latest) : 'N/A' });

  // Test 3: Query specific date (2025-10-26)
  const targetDate = new Date('2025-10-26');
  const nextDay = new Date(targetDate);
  nextDay.setDate(nextDay.getDate() + 1);

  logger.info('Querying date range', { from: targetDate, to: nextDay });
  const onDate = await HealthMetric.findOne({
    userUid: demoUid,
    date: { $gte: targetDate, $lt: nextDay },
  }).lean();

  if (onDate) {
    logger.info('Found document for 2025-10-26');
    logger.info('stepCount', { stepCount: onDate.stepCount });
    logger.info('weightKg', { weightKg: onDate.weightKg });
    logger.info('date', { date: onDate.date });
  } else {
    logger.info('No document found for 2025-10-26');
    logger.info('Checking what dates exist...');
    const allDates = await HealthMetric.find({ userUid: demoUid })
      .select({ date: 1 })
      .sort({ date: -1 })
      .limit(10)
      .lean();
    logger.info('Recent dates in DB', { dates: allDates.map(d => d.date.toISOString().split('T')[0]) });
  }

  // Test 4: Check if userUid field exists
  logger.info('Checking userUid variations...');
  const anyDoc = await HealthMetric.findOne().lean();
  if (anyDoc) {
    logger.info('Sample document userUid field', { userUid: anyDoc.userUid });
    logger.info('All UIDs in collection');
    const uids = await HealthMetric.distinct('userUid');
    logger.info('UIDs', { uids });
  }

  await mongoose.disconnect();
  logger.info('Test complete');
}

main().catch(err => {
  logger.error('Error', { message: err.message });
  process.exit(1);
});

