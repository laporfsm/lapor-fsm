import postgres from 'postgres';

const sql = postgres(process.env.DATABASE_URL!, { ssl: 'require' });

async function migrate() {
    console.log('Checking staff table columns...');
    try {
        console.log('--- Migrating "users" table ---');
        const userColumns = await sql`
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'users';
        `;
        const userColumnNames = userColumns.map(c => c.column_name);

        if (!userColumnNames.includes('is_email_verified')) {
            console.log('Adding "is_email_verified" to users...');
            await sql`ALTER TABLE users ADD COLUMN is_email_verified BOOLEAN DEFAULT FALSE;`;
        }
        if (!userColumnNames.includes('email_verification_token')) {
            console.log('Adding "email_verification_token" to users...');
            await sql`ALTER TABLE users ADD COLUMN email_verification_token TEXT;`;
        }

        console.log('--- Migrating "report_logs" table ---');
        await sql`ALTER TABLE report_logs ALTER COLUMN report_id DROP NOT NULL;`;
        console.log('Successfully dropped NOT NULL from report_logs.report_id');

        console.log('Migration completed successfully.');
    } catch (err) {
        console.error('Error during migration:', err);
    } finally {
        await sql.end();
    }
}

migrate();
