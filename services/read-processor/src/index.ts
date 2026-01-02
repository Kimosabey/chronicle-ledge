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
                await query(
                    `INSERT INTO transactions (transaction_id, account_id, type, amount, balance_after, description, timestamp)
                     SELECT $1, $2, 'deposit', $3, balance, $4, $5
                     FROM account_balance WHERE account_id = $2`,
                    [event.event_id, accountId, data.amount, data.description || 'Deposit', event.created_at]
                );

                console.log(`Processed MoneyDeposited: ${accountId} +${data.amount}`);
            } catch (err) {
                console.error(`Error processing MoneyDeposited for ${accountId}:`, err);
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
                await query(
                    `INSERT INTO transactions (transaction_id, account_id, type, amount, balance_after, description, timestamp)
                     SELECT $1, $2, 'withdrawal', $3, balance, $4, $5
                     FROM account_balance WHERE account_id = $2`,
                    [event.event_id, accountId, data.amount, data.description || 'Withdrawal', event.created_at]
                );

                console.log(`Processed MoneyWithdrawn: ${accountId} -${data.amount}`);
            } catch (err) {
                console.error(`Error processing MoneyWithdrawn for ${accountId}:`, err);
            }
        });

        console.log("Read Processor Service Started");

    } catch (err) {
        console.error("Error starting Read Processor:", err);
    }
};

start();
