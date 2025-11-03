const path = require('path');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

const envPath = path.resolve(__dirname, '..', '.env');
dotenv.config({ path: envPath });

async function main() {
  const uri = process.env.MONGO_URI;
  if (!uri) {
    console.error('❌ MONGO_URI is not set. Please update backend/.env before running this test.');
    process.exit(1);
  }

  console.log('🔍 Testing MongoDB connection using MONGO_URI...');
  try {
    await mongoose.connect(uri, { serverSelectionTimeoutMS: 10000 });
    console.log('✅ Successfully connected to MongoDB.');
  } catch (err) {
    console.error('❌ MongoDB connection failed:', err.message);
  } finally {
    await mongoose.disconnect().catch(() => {});
    process.exit(0);
  }
}

main();

