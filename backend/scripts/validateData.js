const path = require('path');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

const envPath = path.resolve(__dirname, '..', '.env');
dotenv.config({ path: envPath });

const HealthMetric = require('../src/models/HealthMetric');
const UserProfile = require('../src/models/UserProfile');

async function validateHealthMetrics() {
  console.log('\n=== Validating Health Metrics ===');
  
  const metrics = await HealthMetric.find().lean();
  console.log(`Total health metric documents: ${metrics.length}`);
  
  let issuesFound = 0;
  
  // Check for missing dates
  const missingDates = metrics.filter(m => !m.date);
  if (missingDates.length > 0) {
    console.warn(`⚠️  ${missingDates.length} documents missing date field`);
    issuesFound += missingDates.length;
  }
  
  // Check for missing userUid
  const missingUid = metrics.filter(m => !m.userUid);
  if (missingUid.length > 0) {
    console.warn(`⚠️  ${missingUid.length} documents missing userUid field`);
    issuesFound += missingUid.length;
  }
  
  // Check for invalid numeric ranges
  metrics.forEach((m, idx) => {
    if (m.weightKg !== undefined && (m.weightKg < 20 || m.weightKg > 300)) {
      console.warn(`⚠️  Document ${idx}: weightKg out of reasonable range (${m.weightKg}kg)`);
      issuesFound++;
    }
    if (m.bmi !== undefined && (m.bmi < 10 || m.bmi > 60)) {
      console.warn(`⚠️  Document ${idx}: BMI out of reasonable range (${m.bmi})`);
      issuesFound++;
    }
    if (m.sleepDurationHr !== undefined && (m.sleepDurationHr < 0 || m.sleepDurationHr > 24)) {
      console.warn(`⚠️  Document ${idx}: sleepDurationHr out of range (${m.sleepDurationHr}h)`);
      issuesFound++;
    }
    if (m.restingHeartRateBpm !== undefined && (m.restingHeartRateBpm < 30 || m.restingHeartRateBpm > 200)) {
      console.warn(`⚠️  Document ${idx}: restingHeartRateBpm out of range (${m.restingHeartRateBpm} bpm)`);
      issuesFound++;
    }
    if (m.spo2Percent !== undefined && (m.spo2Percent < 50 || m.spo2Percent > 100)) {
      console.warn(`⚠️  Document ${idx}: spo2Percent out of range (${m.spo2Percent}%)`);
      issuesFound++;
    }
  });
  
  if (issuesFound === 0) {
    console.log('✅ All health metric documents passed validation');
  } else {
    console.log(`\n⚠️  Found ${issuesFound} total issues in health metrics`);
  }
  
  return issuesFound;
}

async function validateUserProfiles() {
  console.log('\n=== Validating User Profiles ===');
  
  const profiles = await UserProfile.find().lean();
  console.log(`Total user profile documents: ${profiles.length}`);
  
  let issuesFound = 0;
  
  // Check for missing uid
  const missingUid = profiles.filter(p => !p.uid);
  if (missingUid.length > 0) {
    console.warn(`⚠️  ${missingUid.length} profiles missing uid field`);
    issuesFound += missingUid.length;
  }
  
  // Check for invalid age
  profiles.forEach((p, idx) => {
    if (p.age !== undefined && (p.age < 0 || p.age > 120)) {
      console.warn(`⚠️  Profile ${idx}: age out of range (${p.age})`);
      issuesFound++;
    }
    if (p.heightCm !== undefined && (p.heightCm < 30 || p.heightCm > 260)) {
      console.warn(`⚠️  Profile ${idx}: heightCm out of range (${p.heightCm}cm)`);
      issuesFound++;
    }
  });
  
  if (issuesFound === 0) {
    console.log('✅ All user profile documents passed validation');
  } else {
    console.log(`\n⚠️  Found ${issuesFound} total issues in user profiles`);
  }
  
  return issuesFound;
}

async function computeDerivedMetrics() {
  console.log('\n=== Computing Derived Metrics ===');
  
  const demoUid = process.env.DEMO_UID || 'demo-shared';
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 7);
  
  const metrics = await HealthMetric.find({
    userUid: demoUid,
    date: { $gte: cutoff },
  })
    .sort({ date: -1 })
    .lean();
  
  if (metrics.length === 0) {
    console.log('⚠️  No recent data found for derived metrics computation');
    return;
  }
  
  // Compute 7-day averages
  const steps = metrics.map(m => m.stepCount).filter(v => v !== undefined && v !== null);
  const sleep = metrics.map(m => m.sleepDurationHr).filter(v => v !== undefined && v !== null);
  const stress = metrics.map(m => m.stressLevel).filter(v => v !== undefined && v !== null);
  
  const avgSteps = steps.length ? (steps.reduce((a, b) => a + b, 0) / steps.length).toFixed(0) : 'N/A';
  const avgSleep = sleep.length ? (sleep.reduce((a, b) => a + b, 0) / sleep.length).toFixed(1) : 'N/A';
  const avgStress = stress.length ? (stress.reduce((a, b) => a + b, 0) / stress.length).toFixed(0) : 'N/A';
  
  console.log('7-day rolling averages for [redacted UID]:');
  console.log(`  Steps: ${avgSteps} steps/day`);
  console.log(`  Sleep: ${avgSleep} hours/night`);
  console.log(`  Stress: ${avgStress}/100`);
  console.log('\n✅ Derived metrics computed successfully');
}

async function main() {
  const uri = process.env.MONGO_URI;
  if (!uri) {
    console.error('❌ MONGO_URI is not set. Please update backend/.env before running this script.');
    process.exit(1);
  }

  console.log('🔍 Connecting to MongoDB...');
  await mongoose.connect(uri);
  console.log('✅ Connected\n');

  let totalIssues = 0;
  
  totalIssues += await validateHealthMetrics();
  totalIssues += await validateUserProfiles();
  await computeDerivedMetrics();

  await mongoose.disconnect();
  
  console.log('\n' + '='.repeat(50));
  if (totalIssues === 0) {
    console.log('✅ All data quality checks passed');
  } else {
    console.log(`⚠️  Total issues found: ${totalIssues}`);
    console.log('Consider reviewing and cleaning the data before relying on it for analytics.');
  }
  console.log('='.repeat(50));
}

main().catch(err => {
  console.error('❌ Error:', err.message);
  process.exit(1);
});





