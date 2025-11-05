const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const dotenv = require('dotenv');
const mongoose = require('mongoose');
const Groq = require('groq-sdk');
const admin = require('./utils/firebaseAdmin');

dotenv.config();

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

app.use(rateLimit({ windowMs: 60_000, max: 100 }));

app.get('/health', (_req, res) => res.json({ ok: true }));

app.use('/auth', require('./routes/authRoutes'));
app.use('/ai', require('./routes/chatRoutes'));
app.use('/', require('./routes/doctorRoutes'));
app.use('/', require('./routes/appointmentRoutes'));
app.use('/', require('./routes/healthRoutes'));
app.use('/', require('./routes/medicationRoutes'));
app.use('/profile', require('./routes/profileRoutes'));

const PORT = process.env.PORT || 5000;

async function checkMongoConnection() {
  try {
    if (mongoose.connection.readyState === 1) {
      // Test with a simple ping
      await mongoose.connection.db.admin().ping();
      console.log('✅ MongoDB Atlas connection completed');
      return true;
    } else {
      console.log('❌ MongoDB Atlas connection failed: Not connected');
      return false;
    }
  } catch (err) {
    console.log(`❌ MongoDB Atlas connection failed: ${err.message}`);
    return false;
  }
}

async function checkGroqConnection() {
  try {
    if (!process.env.GROQ_API_KEY) {
      console.log('❌ Groq API connection failed: GROQ_API_KEY not set');
      return false;
    }

    const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
    // Test with a minimal API call - list models
    await groq.models.list();
    console.log('✅ Groq API connection completed');
    return true;
  } catch (err) {
    console.log(`❌ Groq API connection failed: ${err.message}`);
    return false;
  }
}

async function checkFirebaseConnection() {
  try {
    if (!admin.apps.length) {
      console.log('❌ Firebase Admin connection failed: Admin app not initialized');
      return false;
    }

    // Test Firebase Admin by checking if we can access the app
    const app = admin.app();
    if (app) {
      console.log('✅ Firebase Admin connection completed');
      return true;
    } else {
      console.log('❌ Firebase Admin connection failed: App not accessible');
      return false;
    }
  } catch (err) {
    console.log(`❌ Firebase Admin connection failed: ${err.message}`);
    return false;
  }
}

async function start() {
  try {
    // MongoDB connection
    if (process.env.MONGO_URI) {
      await mongoose.connect(process.env.MONGO_URI);
      console.log('MongoDB connected');
      
      // Run connection checks after MongoDB connects
      await checkMongoConnection();
      await checkGroqConnection();
      await checkFirebaseConnection();
    } else {
      console.warn('MONGO_URI not set; starting without DB');
      // Still check other services even if MongoDB is not configured
      await checkGroqConnection();
      await checkFirebaseConnection();
    }
    
    app.listen(PORT, () => console.log(`API listening on http://localhost:${PORT}`));
  } catch (err) {
    console.error('Startup error:', err);
    process.exit(1);
  }
}

start();


