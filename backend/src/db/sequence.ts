import { sql } from 'drizzle-orm';
import { db } from './index';

type SequenceTarget = {
  table: string;
  column: string;
};

const SERIAL_SEQUENCES: SequenceTarget[] = [
  { table: 'users', column: 'id' },
  { table: 'staff', column: 'id' },
  { table: 'locations', column: 'id' },
  { table: 'specializations', column: 'id' },
  { table: 'categories', column: 'id' },
  { table: 'reports', column: 'id' },
  { table: 'report_logs', column: 'id' },
  { table: 'notifications', column: 'id' },
];

async function syncSingleSequence(target: SequenceTarget) {
  const { table, column } = target;

  // Keep sequence aligned with existing max(id) so next insert won't collide.
  await db.execute(
    sql.raw(`
      SELECT setval(
        pg_get_serial_sequence('${table}', '${column}'),
        COALESCE((SELECT MAX(${column}) FROM ${table}), 1),
        EXISTS (SELECT 1 FROM ${table})
      );
    `),
  );
}

export async function syncAllSerialSequences() {
  for (const target of SERIAL_SEQUENCES) {
    await syncSingleSequence(target);
  }
}
