import postgres from 'postgres';

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
    console.error("DATABASE_URL is not set");
    process.exit(1);
}

const sql = postgres(connectionString);

async function main() {
    console.log("Dropping and recreating public schema...");
    await sql`DROP SCHEMA public CASCADE;`;
    await sql`CREATE SCHEMA public;`;
    await sql`GRANT ALL ON SCHEMA public TO public;`;
    console.log("Schema reset successfully.");
    process.exit(0);
}

main().catch(err => {
    console.error("Error resetting schema:", err);
    process.exit(1);
});
