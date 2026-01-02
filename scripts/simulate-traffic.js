
const API_URL = 'http://localhost:4002'; // Ledger API

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function createAccount(id, name, balance) {
    try {
        const res = await fetch(`${API_URL}/commands/create-account`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                account_id: id,
                owner_name: name,
                initial_balance: balance,
                currency: 'USD'
            })
        });
        const data = await res.json();
        if (res.ok) {
            console.log(`✅ Created account ${id}`);
            return true;
        } else {
            // It's okay if it already exists (we might run this multiple times)
            console.log(`ℹ️ Account ${id} creation skipped: ${data.error}`);
            return true;
        }
    } catch (e) {
        console.error(`❌ Failed to create account ${id}:`, e.message);
        return false;
    }
}

async function transfer(from, to, amount) {
    try {
        const res = await fetch(`${API_URL}/commands/transfer`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                from_account_id: from,
                to_account_id: to,
                amount: amount,
                description: `Chaos test transfer`
            })
        });
        const data = await res.json();
        if (res.ok) {
            process.stdout.write('.'); // Dot for success
            return true;
        } else {
            process.stdout.write('F'); // F for failed logic (insufficient funds etc)
            // console.log(`\nFailed: ${data.error}`);
            // If insufficient funds, let's deposit some back
            if (data.error && data.error.includes('Insufficient funds')) {
                await deposit(from, 1000);
            }
            return false;
        }
    } catch (e) {
        process.stdout.write('X'); // X for network/server error (what we expect during chaos)
        return false;
    }
}

async function deposit(id, amount) {
    try {
        await fetch(`${API_URL}/commands/deposit`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                account_id: id,
                amount: amount,
                description: 'Refill'
            })
        });
        process.stdout.write('D'); // D for Deposit
    } catch (e) {
        console.error(`\nFailed to deposit to ${id}:`, e.message);
    }
}

async function main() {
    console.log("🚀 Starting Chaos Traffic Simulation...");
    console.log("Press Ctrl+C to stop.");

    // Setup
    await createAccount('CHAOS-A', 'Chaos Alice', 1000);
    await createAccount('CHAOS-B', 'Chaos Bob', 1000);

    let count = 0;
    const isContinuous = process.argv.includes('--continuous');

    while (true) {
        count++;
        if (count % 50 === 0) console.log(`\n[${count} txs]`);

        // Random direction
        if (Math.random() > 0.5) {
            await transfer('CHAOS-A', 'CHAOS-B', 10 + Math.random() * 50);
        } else {
            await transfer('CHAOS-B', 'CHAOS-A', 10 + Math.random() * 50);
        }

        await sleep(200); // 5 tx/sec approx

        if (!isContinuous && count >= 100) break;
    }
}

main();
