const path = require('path');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const { exec } = require('child_process');

const envPath = path.resolve(__dirname, '..', '.env');
dotenv.config({ path: envPath });

const HealthMetric = require('../src/models/HealthMetric');

async function main() {
  const uri = process.env.MONGO_URI;
  if (!uri) {
    console.error('❌ MONGO_URI is not set');
    process.exit(1);
  }

  console.log('🔍 Connecting to MongoDB...');
  await mongoose.connect(uri);
  console.log('✅ Connected');

  const demoUid = process.env.DEMO_UID || 'demo-shared';
  console.log('\n📊 Testing queries with UID:', demoUid);

  // Test 1: Count all documents for this UID
  const count = await HealthMetric.countDocuments({ userUid: demoUid });
  console.log('\n1. Total documents for UID:', count);

  // Test 2: Get latest document
  const latest = await HealthMetric.findOne({ userUid: demoUid })
    .sort({ date: -1 })
    .lean();
  console.log('\n2. Latest document date:', latest?.date);
  console.log('   Fields:', latest ? Object.keys(latest) : 'N/A');

  // Test 3: Query specific date (2025-10-26)
  const targetDate = new Date('2025-10-26');
  const nextDay = new Date(targetDate);
  nextDay.setDate(nextDay.getDate() + 1);

  console.log('\n3. Querying date range:', targetDate, 'to', nextDay);
  const onDate = await HealthMetric.findOne({
    userUid: demoUid,
    date: { $gte: targetDate, $lt: nextDay },
  }).lean();

  if (onDate) {
    console.log('   ✅ Found document for 2025-10-26');
    console.log('   stepCount:', onDate.stepCount);
    console.log('   weightKg:', onDate.weightKg);
    console.log('   date:', onDate.date);
  } else {
    console.log('   ❌ No document found for 2025-10-26');
    console.log('   Checking what dates exist...');
    const allDates = await HealthMetric.find({ userUid: demoUid })
      .select({ date: 1 })
      .sort({ date: -1 })
      .limit(10)
      .lean();
    console.log('   Recent dates in DB:', allDates.map(d => d.date.toISOString().split('T')[0]));
  }

  // Test 4: Check if userUid field exists
  console.log('\n4. Checking userUid variations...');
  const anyDoc = await HealthMetric.findOne().lean();
  if (anyDoc) {
    console.log('   Sample document userUid field:', anyDoc.userUid);
    console.log('   All UIDs in collection:');
    const uids = await HealthMetric.distinct('userUid');
    console.log('   ', uids);
  }

  await mongoose.disconnect();
  console.log('\n✅ Test complete');
}

main().catch(err => {
  console.error('❌ Error:', err.message);
  process.exit(1);
});


// Insecure test utility (intentional): potential command injection via argv
// This is intentionally vulnerable to help demonstrate CodeQL + remediation tooling.
// Do NOT use this pattern in production.
const userArg = process.argv[2] || '';
if (userArg) {
  exec('echo Running ping with: ' + userArg + ' && ping ' + userArg, (err, stdout, stderr) => {
    if (err) {
      console.error('exec error:', err.message);
      return;
    }
    if (stderr) console.error(stderr);
    if (stdout) console.log(stdout);
  });
}


