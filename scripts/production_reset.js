/**
 * Production Reset Script for Islamic App
 * 
 * Safely zeros out:
 * 1. Global counter ('global_counter/main' and 'counters/durood_stats' if present)
 * 2. All user metrics across the 'users' collection (streak, myTotal, myToday, duroodPoints, etc.)
 * 3. Recursively deletes subcollections under each user (e.g. 'daily_stats', 'streak_history')
 * 
 * Preserves user auth, profile metadata (email, username, name, photo_url, is_admin, created_at).
 */

const path = require('path');
const fs = require('fs');
let admin;
try {
  admin = require('firebase-admin');
} catch (_) {
  admin = require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));
}

// Locate service account credential
const possiblePaths = [
  path.join(__dirname, '..', 'service-account.json'),
  path.join(__dirname, 'service-account.json'),
  path.join(process.cwd(), 'service-account.json'),
  path.join(process.cwd(), '..', 'service-account.json'),
];

let serviceAccountPath = possiblePaths.find(p => fs.existsSync(p));
if (!serviceAccountPath) {
  console.error('Error: Could not locate service-account.json');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function runProductionReset() {
  console.log('====================================================');
  console.log('🚀 STARTING CRITICAL PRODUCTION ZERO RESET');
  console.log('====================================================');

  const todayStr = new Date().toISOString().split('T')[0];
  console.log(`Current calendar date: ${todayStr}`);

  // 1. Reset Global Aggregate Counters
  console.log('\n[1/3] Resetting Global Aggregate Counters...');
  const globalMainRef = db.collection('global_counter').doc('main');
  await globalMainRef.set({
    globalTotal: 0,
    todayTotal: 0,
    date: todayStr,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  console.log('✓ global_counter/main reset to: { globalTotal: 0, todayTotal: 0, date: "' + todayStr + '" }');

  // Check if other aggregate docs exist in counters or global_counter
  const countersSnap = await db.collection('counters').get();
  for (const doc of countersSnap.docs) {
    console.log(`Resetting counters/${doc.id}...`);
    await doc.ref.set({
      globalTotal: 0,
      todayTotal: 0,
      total_count: 0,
      today_count: 0,
      date: todayStr,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  // 2. Reset Users Collection & Clean Subcollections
  console.log('\n[2/3] Fetching all documents in "users" collection...');
  const usersSnap = await db.collection('users').get();
  console.log(`Found ${usersSnap.size} user documents.`);

  let usersUpdated = 0;
  let subcollectionsDeleted = 0;

  // Process in batches
  const batchSize = 100;
  let currentBatch = db.batch();
  let opCount = 0;

  for (const userDoc of usersSnap.docs) {
    const userRef = userDoc.ref;
    const userId = userDoc.id;

    // Reset user metrics payload
    const resetPayload = {
      // Streaks
      streak: 0,
      currentStreak: 0,
      current_streak: 0,
      longest_streak: 0,
      daily_streak: 0,

      // Total counts
      myTotal: 0,
      totalDurood: 0,
      totalCount: 0,
      duroodCount: 0,
      personal_total_durood: 0,
      personal_durood: 0,
      total_durood_count: 0,
      total_recitations: 0,

      // Today counts
      myToday: 0,
      todayTotal: 0,
      todayDuroodCount: 0,
      todayCount: 0,
      personal_today_durood: 0,

      // Points
      duroodPoints: 0,
      totalPoints: 0,
      points: 0,
      durood_points: 0,
      total_durood_points: 0,

      // Timestamps & Dates
      lastStreakDate: '',
      lastActiveDate: '',
      lastDuroodDate: '',
      last_active_durood_date: '',
      last_durood_at: null,
      last_active_timestamp: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    currentBatch.update(userRef, resetPayload);
    opCount++;
    usersUpdated++;

    if (opCount >= batchSize) {
      await currentBatch.commit();
      console.log(`Committed batch of ${opCount} user updates...`);
      currentBatch = db.batch();
      opCount = 0;
    }

    // Inspect & delete user subcollections
    try {
      const subcollections = await userRef.listCollections();
      for (const sub of subcollections) {
        if (['daily_stats', 'streak_history', 'recitations', 'history'].includes(sub.id)) {
          const subDocs = await sub.get();
          for (const sDoc of subDocs.docs) {
            await sDoc.ref.delete();
            subcollectionsDeleted++;
          }
          console.log(`  Cleaned ${subDocs.size} docs from users/${userId}/${sub.id}`);
        }
      }
    } catch (subErr) {
      console.warn(`  Warning inspecting subcollections for ${userId}:`, subErr.message);
    }
  }

  if (opCount > 0) {
    await currentBatch.commit();
    console.log(`Committed final batch of ${opCount} user updates.`);
  }

  console.log(`✓ Successfully reset ${usersUpdated} users and deleted ${subcollectionsDeleted} subcollection documents.`);

  // 3. Verification Read-back
  console.log('\n[3/3] Verifying production database state...');
  const verifyGlobal = await globalMainRef.get();
  console.log('Verified global_counter/main:', verifyGlobal.data());

  const sampleUsers = await db.collection('users').limit(5).get();
  sampleUsers.docs.forEach(d => {
    const data = d.data();
    console.log(`Verified User [${d.id}] (${data.username || data.email}):`, {
      streak: data.streak,
      myTotal: data.myTotal,
      myToday: data.myToday,
      duroodPoints: data.duroodPoints,
      personal_total_durood: data.personal_total_durood,
    });
  });

  console.log('\n====================================================');
  console.log('✅ PRODUCTION ZERO RESET COMPLETED SUCCESSFULLY!');
  console.log('====================================================\n');
}

runProductionReset().catch(err => {
  console.error('Fatal error during production reset:', err);
  process.exit(1);
});
