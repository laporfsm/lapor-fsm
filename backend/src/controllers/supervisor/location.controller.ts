import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { locations } from '../../db/schema';
import { eq, desc, ilike } from 'drizzle-orm';

export const locationController = new Elysia({ prefix: '/locations' })
    // Get all locations
    .get('/', async ({ query }) => {
        const { search } = query;
        let whereClause;

        if (search) {
            whereClause = ilike(locations.name, `%${search}%`);
        }

        const result = await db
            .select()
            .from(locations)
            .where(whereClause)
            .orderBy(desc(locations.createdAt));

        return {
            status: 'success',
            data: result.map(l => ({
                id: l.id.toString(), // Convert to string for mobile
                name: l.name,
                createdAt: l.createdAt
            }))
        };
    })

    // Create location
    .post('/', async ({ body }) => {
        try {
            const { name } = body;
            const existing = await db.select().from(locations).where(eq(locations.name, name)).limit(1);

            if (existing.length > 0) {
                return { status: 'error', message: 'Lokasi dengan nama tersebut sudah ada' };
            }

            const newLocation = await db.insert(locations).values({ name }).returning();

            return {
                status: 'success',
                data: {
                    id: newLocation[0].id.toString(),
                    name: newLocation[0].name,
                    createdAt: newLocation[0].createdAt
                },
                message: 'Lokasi berhasil ditambahkan'
            };
        } catch (e) {
            return { status: 'error', message: 'Gagal menambahkan lokasi' };
        }
    }, {
        body: t.Object({ name: t.String() })
    })

    // Update location
    .put('/:id', async ({ params, body }) => {
        try {
            const id = parseInt(params.id);
            const { name } = body;

            const existing = await db.select().from(locations).where(eq(locations.name, name)).limit(1);
            if (existing.length > 0 && existing[0].id !== id) {
                return { status: 'error', message: 'Nama lokasi sudah digunakan' };
            }

            const updated = await db
                .update(locations)
                .set({ name })
                .where(eq(locations.id, id))
                .returning();

            if (updated.length === 0) {
                return { status: 'error', message: 'Lokasi tidak ditemukan' };
            }

            return {
                status: 'success',
                data: {
                    id: updated[0].id.toString(),
                    name: updated[0].name,
                },
                message: 'Lokasi berhasil diupdate'
            };
        } catch (e) {
            return { status: 'error', message: 'Gagal mengupdate lokasi' };
        }
    }, {
        body: t.Object({ name: t.String() })
    })

    // Delete location
    .delete('/:id', async ({ params }) => {
        try {
            const id = parseInt(params.id);
            // TODO: Check usage in reports/staff before delete?

            const deleted = await db.delete(locations).where(eq(locations.id, id)).returning();

            if (deleted.length === 0) {
                return { status: 'error', message: 'Lokasi tidak ditemukan' };
            }

            return {
                status: 'success',
                message: 'Lokasi berhasil dihapus'
            };
        } catch (e) {
            return { status: 'error', message: 'Gagal menghapus lokasi (Mungkin sedang digunakan)' };
        }
    });
