#!/usr/bin/env node
const axios = require('axios');
const path = require('path');
const dotenv = require('dotenv');

// Load environment variables from ../.env if present
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const apiKey = process.env.GROQ_API_KEY;

if (!apiKey) {
  console.error('❌ GROQ_API_KEY is not set. Please add it to backend/.env before running this test.');
  process.exit(1);
}

async function testGroqConnection() {
  console.log('🔍 Testing connection to Groq chat completions API...');

  const models = [
    ...(process.env.GROQ_MODEL ? [process.env.GROQ_MODEL] : []),
    'llama-3.1-8b-instant',
    'llama-3.1-70b-versatile',
    'mixtral-8x7b-32768',
  ];

  let lastError;

  for (const model of models) {
    try {
      console.log(`→ Trying model: ${model}`);
      const response = await axios.post(
        'https://api.groq.com/openai/v1/chat/completions',
        {
          model,
          temperature: 0.2,
          max_tokens: 32,
          messages: [
            { role: 'system', content: 'You are a simple status probe confirming API connectivity.' },
            { role: 'user', content: 'Reply with the word CONNECTED.' },
          ],
        },
        {
          headers: {
            Authorization: `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 10000,
        }
      );

      const reply = response.data?.choices?.[0]?.message?.content ?? '';
      console.log('✅ Groq API responded successfully.');
      console.log('--- Raw reply ---');
      console.log(reply.trim());
      return;
    } catch (error) {
      lastError = error;
      const status = error.response?.status;
      const message = error.response?.data?.error?.message || error.message || 'Unknown error';
      console.warn(`⚠️  Model ${model} failed (${status ?? 'no status'}): ${message}`);

      const retry =
        status === 429 ||
        status === 503 ||
        (typeof message === 'string' &&
          (message.toLowerCase().includes('over capacity') ||
            message.toLowerCase().includes('temporarily unavailable') ||
            message.toLowerCase().includes('model')));

      if (!retry) {
        break;
      }
    }
  }

  console.error('❌ Groq test failed for all models attempted.');
  if (lastError) {
    const status = lastError.response?.status;
    const data = lastError.response?.data;
    if (status) console.error(`Status: ${status}`);
    if (data) {
      console.error('Response body:', JSON.stringify(data, null, 2));
    } else {
      console.error('Error message:', lastError.message);
    }
  }
  process.exit(1);
}

testGroqConnection();

