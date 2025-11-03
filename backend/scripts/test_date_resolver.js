#!/usr/bin/env node

/**
 * Test script for dateResolver
 * Tests various natural language date phrases including typos
 */

const path = require('path');
const dotenv = require('dotenv');

// Load environment variables
const envPath = path.resolve(__dirname, '..', '.env');
dotenv.config({ path: envPath });

const { resolveDate } = require('../src/utils/dateResolver');

async function testDateResolver() {
  console.log('=== Date Resolver Test Suite ===\n');

  const testCases = [
    'what was my bmi a month ago',
    'what was my bmi a mouth ago', // typo
    'show me my weight yesterday',
    'my steps 30 days ago',
    'sleep last week',
    'heart rate 2 weeks ago',
    'stress level last month',
    'weight on 2025-10-26',
    'bmi on Oct 26',
    'steps last monday',
    'what was my weight yday', // typo
    'show data from last 7 days',
    'average over past month',
  ];

  for (const testCase of testCases) {
    console.log(`Test: "${testCase}"`);
    try {
      const result = await resolveDate(testCase);
      if (result) {
        console.log(`  ✓ Resolved (${result.strategy}):`, {
          kind: result.kind,
          start: result.start.toISOString().split('T')[0],
          end: result.end.toISOString().split('T')[0],
          confidence: result.confidence,
        });
      } else {
        console.log('  ✗ Could not resolve date');
      }
    } catch (error) {
      console.log('  ✗ Error:', error.message);
    }
    console.log('');
  }

  console.log('=== Test Complete ===');
  process.exit(0);
}

testDateResolver().catch(err => {
  console.error('Test script failed:', err);
  process.exit(1);
});

