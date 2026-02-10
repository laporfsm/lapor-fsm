import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { specializations } from '../../db/schema';
import { eq, desc, ilike } from 'drizzle-orm';

export const specializationController = new Elysia({ prefix: '/specializations' })
    // Get all specializations
    .get('/', async ({ query }) => {
        const { search } = query;
        let whereClause;

        if (search) {
            whereClause = ilike(specializations.name, `%${search}%`);
        }

        const result = await db
            .select()
            .from(specializations)
            .where(whereClause)
            .orderBy(desc(specializations.id));

        return {
            status: 'success',
            data: result.map(s => ({
                id: s.id.toString(),
                name: s.name,
                icon: s.icon,
                description: s.description
            }))
        };
    })

    // Create specialization
    .post('/', async ({ body }) => {
        try {
            const { name, icon, description } = body;
            const existing = await db.select().from(specializations).where(eq(specializations.name, name)).limit(1);

            if (existing.length > 0) {
                return { status: 'error', message: 'Spesialisasi dengan nama tersebut sudah ada' };
            }

            const newSpec = await db.insert(specializations).values({
                name,
                icon: icon ?? 'wrench',
                description
            }).returning();

            return {
                status: 'success',
                data: {
                    id: newSpec[0].id.toString(),
                    name: newSpec[0].name,
                    icon: newSpec[0].icon,
                    description: newSpec[0].description
                },
                message: 'Spesialisasi berhasil ditambahkan'
            };
        } catch (e) {
            return { status: 'error', message: 'Gagal menambahkan spesialisasi' };
        }
    }, {
        body: t.Object({
            name: t.String(),
            icon: t.Optional(t.String()),
            description: t.Optional(t.String())
        })
    })

    // Update specialization
    .put('/:id', async ({ params, body }) => {
        try {
            const id = parseInt(params.id);
            const { name, icon, description } = body;

            const existing = await db.select().from(specializations).where(eq(specializations.name, name)).limit(1);
            if (existing.length > 0 && existing[0].id !== id) {
                return { status: 'error', message: 'Nama spesialisasi sudah digunakan' };
            }

            const updated = await db
                .update(specializations)
                .set({ name, icon, description })
                .where(eq(specializations.id, id))
                .returning();

            if (updated.length === 0) {
                return { status: 'error', message: 'Spesialisasi tidak ditemukan' };
            }

            return {
                status: 'success',
                data: {
                    id: updated[0].id.toString(),
                    name: updated[0].name,
                    icon: updated[0].icon,
                    description: updated[0].description
                },
                message: 'Spesialisasi berhasil diupdate'
            };
        } catch (e) {
            return { status: 'error', message: 'Gagal mengupdate spesialisasi' };
        }
    }, {
        body: t.Object({
            name: t.String(),
            icon: t.Optional(t.String()),
            description: t.Optional(t.String())
        })
    })

    // Delete specialization
    .delete('/:id', async ({ params }) => {
        try {
            const id = parseInt(params.id);
            const deleted = await db.delete(specializations).where(eq(specializations.id, id)).returning();

            if (deleted.length === 0) {
                return { status: 'error', message: 'Spesialisasi tidak ditemukan' };
            }

            return {
                status: 'success',
                message: 'Spesialisasi berhasil dihapus'
            };
        } catch (e) {
            return { status: 'error', message: 'Gagal menghapus spesialisasi (Mungkin sedang digunakan)' };
        }
    });
