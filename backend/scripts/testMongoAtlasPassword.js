const mongoose = require('mongoose');

function extractRedactedUri(uri) {
  return uri.replace(/\/\/([^:]+):([^@]+)@/, '//$1:****@');
}

async function testConnection() {
  const fromEnv = process.env.MONGO_URI_TEST;
  const fromArg = process.argv[2];

  if (!fromEnv && !fromArg) {
    console.error(
      '❌ No MongoDB URI provided.\n' +
        'Pass it as an argument or set MONGO_URI_TEST in your environment.\n\n' +
        'Examples:\n' +
        '  node scripts/testMongoAtlasPassword.js "mongodb+srv://user:pass@host/db"\n' +
        '  $env:MONGO_URI_TEST="mongodb+srv://user:pass@host/db"; node scripts/testMongoAtlasPassword.js'
    );
    process.exit(1);
  }

  const uri = fromArg || fromEnv;
  console.log('🔍 Testing MongoDB connection to:');
  console.log('   ' + extractRedactedUri(uri));

  const startedAt = Date.now();
  try {
    await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 10000,
      connectTimeoutMS: 10000,
    });

    const db = mongoose.connection.db;
    const admin = db.admin();
    const serverStatus = await admin.serverStatus();
    const elapsed = ((Date.now() - startedAt) / 1000).toFixed(2);

    console.log('✅ Connection successful.');
    console.log('   Host          :', serverStatus.host || 'n/a');
    console.log('   Version       :', serverStatus.version || 'n/a');
    console.log('   Database      :', db.databaseName || '(default)');
    console.log('   Ping time     :', elapsed + 's');
  } catch (err) {
    const elapsed = ((Date.now() - startedAt) / 1000).toFixed(2);
    console.error(`❌ Connection failed after ${elapsed}s:`);
    console.error('   ' + (err.message || err));
    if (/bad auth|authentication failed|invalid username or password/i.test(err.message || '')) {
      console.error('\n💡 This usually means the username or password is wrong.');
      console.error('   - URL-encode special characters in the password (e.g. @ -> %40, # -> %23)');
      console.error('   - Make sure the database user exists in MongoDB Atlas → Database Access');
      console.error('   - Confirm the user has access to the specified database');
    } else if (/getaddrinfo ENOTFOUND|querySrv|ETIMEDOUT|ECONNREFUSED/i.test(err.message || '')) {
      console.error('\n💡 Network/DNS issue. Check the cluster hostname and your IP allowlist in Atlas.');
    }
    process.exitCode = 1;
  } finally {
    await mongoose.disconnect().catch(() => {});
    process.exit(process.exitCode || 0);
  }
}

testConnection();
