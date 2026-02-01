import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema';

// Database connection string from environment
const connectionString = process.env.DATABASE_URL || 'postgres://postgres:postgres@localhost:5432/laporfsm';

// Create postgres client
const client = postgres(connectionString, { prepare: false });

// Create drizzle database instance
export const db = drizzle(client, { schema });

export default db;
