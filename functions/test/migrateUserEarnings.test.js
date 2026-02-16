const assert = require("assert");

const {
  _test_buildUserEarningsMigrationPlan,
} = require("../index");

function makeDoc(id, data) {
  return { id, data };
}

function run() {
  // aggregates totals from user and realtime without coins
  {
    const uid = "user1";
    const userData = {
      totalPoints: 100,
      mining: {
        hourlyRate: 2,
      },
    };
    const realtimeData = {
      totalPoints: 50,
      hourlyRate: 3,
    };

    const plan = _test_buildUserEarningsMigrationPlan({
      uid,
      userData,
      realtimeData,
      subCoinsDocs: [],
      globalCoinsDocs: [],
    });

    assert.strictEqual(plan.finalTotalPoints, 150);
    assert.strictEqual(plan.newUserDoc.totalPoints, 150);
    assert.strictEqual(plan.newRealtimeDoc.totalPoints, 150);

    const mining = plan.newUserDoc.mining;
    assert.ok(mining);
    assert.strictEqual("totalPoints" in mining, false);
  }

  // handles missing totals and zero balances
  {
    const uid = "user2";
    const userData = {};
    const realtimeData = {};

    const plan = _test_buildUserEarningsMigrationPlan({
      uid,
      userData,
      realtimeData,
      subCoinsDocs: [],
      globalCoinsDocs: [],
    });

    assert.strictEqual(plan.finalTotalPoints, 0);
    assert.strictEqual(plan.newUserDoc.totalPoints, 0);
    assert.strictEqual(plan.newRealtimeDoc.totalPoints, 0);
  }

  // merges coin totals from multiple sources per coin id
  {
    const uid = "user3";
    const userData = {};
    const realtimeData = {};

    const subCoinsDocs = [
      makeDoc("btc", {
        ownerId: uid,
        name: "Bitcoin",
        symbol: "BTC",
        totalPoints: 10,
        hourlyRate: 1,
      }),
    ];

    const globalCoinsDocs = [
      makeDoc("btc", {
        ownerId: uid,
        totalPoints: 5,
        hourlyRate: 2,
      }),
      makeDoc("eth", {
        ownerId: uid,
        totalPoints: 3,
        hourlyRate: 1.5,
      }),
    ];

    const plan = _test_buildUserEarningsMigrationPlan({
      uid,
      userData,
      realtimeData,
      subCoinsDocs,
      globalCoinsDocs,
    });

    const coinsUser = plan.newUserDoc.wallet.coins;
    const coinsRealtime = plan.newRealtimeDoc.coins;

    assert.strictEqual(coinsUser.btc.totalPoints, 15);
    assert.strictEqual(coinsRealtime.btc.totalPoints, 15);
    assert.strictEqual(coinsUser.eth.totalPoints, 3);
    assert.strictEqual(coinsRealtime.eth.totalPoints, 3);
  }

  // partial user data with only realtime total
  {
    const uid = "user4";
    const userData = {
      mining: {
        hourlyRate: 1.5,
      },
    };
    const realtimeData = {
      totalPoints: 40,
    };

    const plan = _test_buildUserEarningsMigrationPlan({
      uid,
      userData,
      realtimeData,
      subCoinsDocs: [],
      globalCoinsDocs: [],
    });

    assert.strictEqual(plan.finalTotalPoints, 40);
    assert.strictEqual(plan.newUserDoc.totalPoints, 40);
    assert.strictEqual(plan.newRealtimeDoc.totalPoints, 40);
  }

  console.log("All migrateUserEarnings tests passed");
}

run();
