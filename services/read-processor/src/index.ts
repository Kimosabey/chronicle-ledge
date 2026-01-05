import { connectNats, subscribe } from './nats';
import { query } from './db';

const start = async () => {
    try {
        await connectNats();

        // Subscribe to AccountCreated events
        subscribe('events.account.created', async (event: any) => {
            console.log('Received AccountCreated event:', event.event_id);
            const data = event.event_data;

            try {
                // Upsert into account_balance (idempotent)
                await query(
                    `INSERT INTO account_balance (account_id, owner_name, balance, currency, status)
                     VALUES ($1, $2, $3, $4, 'active')
                     ON CONFLICT (account_id) DO NOTHING`,
                    [data.account_id, data.owner_name, data.initial_balance, data.currency]
                );
                console.log(`Processed AccountCreated: ${data.account_id}`);
            } catch (err) {
                console.error(`Error processing AccountCreated for ${data.account_id}:`, err);
            }
        });

        // Subscribe to MoneyDeposited events
        subscribe('events.account.deposited', async (event: any) => {
            console.log('Received MoneyDeposited event:', event.event_id);
            const data = event.event_data;
            const accountId = event.aggregate_id;

            try {
                // Increment balance
                await query(
                    `UPDATE account_balance 
                     SET balance = balance + $1, last_updated = NOW() 
                     WHERE account_id = $2`,
                    [data.amount, accountId]
                );

                // Record transaction
                const transRes = await query(
                    `INSERT INTO transactions (transaction_id, account_id, type, amount, balance_after, description, timestamp)
                     SELECT $1::uuid, $2::varchar, 'deposit', $3::decimal, balance, $4::text, $5::timestamptz
                     FROM account_balance WHERE account_id = $2::varchar
                     RETURNING *`,
                    [event.event_id, accountId, data.amount, data.description || 'Deposit', event.created_at]
                );

                if (transRes.rowCount === 0) {
                    console.error(`Failed to insert deposit transaction for ${accountId} - Account likely not found in DB yet.`);
                }

                // Populate Transfers Table
                if (data.transfer_id && data.sender) {
                    await query(
                        `INSERT INTO transfers (transfer_id, from_account_id, to_account_id, amount, description, status, timestamp)
                         VALUES ($1::uuid, $2::varchar, $3::varchar, $4::decimal, $5::text, 'completed', $6::timestamptz)
                         ON CONFLICT (transfer_id) DO NOTHING`,
                        [data.transfer_id, data.sender, accountId, data.amount, data.description, event.created_at]
                    );
                    console.log(`Processed Transfer (Deposit side): ${data.transfer_id}`);
                }

                console.log(`Processed MoneyDeposited: ${accountId} +${data.amount}`);
            } catch (err) {
                console.error(`Error processing MoneyDeposited for ${accountId}:`, err);
                console.error('Event Data:', JSON.stringify(data));
            }
        });

        // Subscribe to MoneyWithdrawn events
        subscribe('events.account.withdrawn', async (event: any) => {
            console.log('Received MoneyWithdrawn event:', event.event_id);
            const data = event.event_data;
            const accountId = event.aggregate_id;

            try {
                // Decrement balance
                await query(
                    `UPDATE account_balance 
                     SET balance = balance - $1, last_updated = NOW() 
                     WHERE account_id = $2`,
                    [data.amount, accountId]
                );

                // Record transaction
                const transRes = await query(
                    `INSERT INTO transactions (transaction_id, account_id, type, amount, balance_after, description, timestamp)
                     SELECT $1::uuid, $2::varchar, 'withdrawal', $3::decimal, balance, $4::text, $5::timestamptz
                     FROM account_balance WHERE account_id = $2::varchar
                     RETURNING *`,
                    [event.event_id, accountId, data.amount, data.description || 'Withdrawal', event.created_at]
                );

                if (transRes.rowCount === 0) {
                    console.error(`Failed to insert withdrawal transaction for ${accountId} - Account likely not found in DB yet.`);
                }

                // Populate Transfers Table
                if (data.transfer_id && data.recipient) {
                    await query(
                        `INSERT INTO transfers (transfer_id, from_account_id, to_account_id, amount, description, status, timestamp)
                         VALUES ($1::uuid, $2::varchar, $3::varchar, $4::decimal, $5::text, 'completed', $6::timestamptz)
                         ON CONFLICT (transfer_id) DO NOTHING`,
                        [data.transfer_id, accountId, data.recipient, data.amount, data.description, event.created_at]
                    );
                    console.log(`Processed Transfer (Withdrawal side): ${data.transfer_id}`);
                }

                console.log(`Processed MoneyWithdrawn: ${accountId} -${data.amount}`);
            } catch (err) {
                console.error(`Error processing MoneyWithdrawn for ${accountId}:`, err);
                console.error('Event Data:', JSON.stringify(data));
            }
        });

        console.log("Read Processor Service Started");

    } catch (err) {
        console.error("Error starting Read Processor:", err);
    }
};

start();
