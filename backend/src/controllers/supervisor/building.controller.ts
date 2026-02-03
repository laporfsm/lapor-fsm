import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { buildings } from '../../db/schema';
import { eq, desc, ilike } from 'drizzle-orm';

export const buildingController = new Elysia({ prefix: '/buildings' })
    // Get all buildings
    .get('/', async ({ query }) => {
        const { search } = query;
        let whereClause;

        if (search) {
            whereClause = ilike(buildings.name, `%${search}%`);
        }

        const result = await db
            .select()
            .from(buildings)
            .where(whereClause)
            .orderBy(desc(buildings.createdAt));

        return {
            status: 'success',
            data: result.map(b => ({
                id: b.id.toString(), // Convert to string for mobile
                name: b.name,
                createdAt: b.createdAt
            }))
        };
    })

    // Create building
    .post('/', async ({ body }) => {
        try {
            const { name } = body;
            const existing = await db.select().from(buildings).where(eq(buildings.name, name)).limit(1);

            if (existing.length > 0) {
                return { status: 'error', message: 'Gedung dengan nama tersebut sudah ada' };
            }

            const newBuilding = await db.insert(buildings).values({ name }).returning();

            return {
                status: 'success',
                data: {
                    id: newBuilding[0].id.toString(),
                    name: newBuilding[0].name,
                    createdAt: newBuilding[0].createdAt
                },
                message: 'Gedung berhasil ditambahkan'
            };
        } catch (e) {
            return { status: 'error', message: 'Gagal menambahkan gedung' };
        }
    }, {
        body: t.Object({ name: t.String() })
    })

    // Update building
    .put('/:id', async ({ params, body }) => {
        try {
            const id = parseInt(params.id);
            const { name } = body;

            const existing = await db.select().from(buildings).where(eq(buildings.name, name)).limit(1);
            if (existing.length > 0 && existing[0].id !== id) {
                return { status: 'error', message: 'Nama gedung sudah digunakan' };
            }

            const updated = await db
                .update(buildings)
                .set({ name })
                .where(eq(buildings.id, id))
                .returning();

            if (updated.length === 0) {
                return { status: 'error', message: 'Gedung tidak ditemukan' };
            }

            return {
                status: 'success',
                data: {
                    id: updated[0].id.toString(),
                    name: updated[0].name,
                },
                message: 'Gedung berhasil diupdate'
            };
        } catch (e) {
            return { status: 'error', message: 'Gagal mengupdate gedung' };
        }
    }, {
        body: t.Object({ name: t.String() })
    })

    // Delete building
    .delete('/:id', async ({ params }) => {
        try {
            const id = parseInt(params.id);
            // TODO: Check usage in reports/staff before delete?
            // For now allow hard delete, or handle FK violation

            const deleted = await db.delete(buildings).where(eq(buildings.id, id)).returning();

            if (deleted.length === 0) {
                return { status: 'error', message: 'Gedung tidak ditemukan' };
            }

            return {
                status: 'success',
                message: 'Gedung berhasil dihapus'
            };
        } catch (e) {
            // Probably integrity constraint if referenced
            return { status: 'error', message: 'Gagal menghapus gedung (Mungkin sedang digunakan)' };
        }
    });
