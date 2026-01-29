import { Elysia, t } from 'elysia';
import { db } from '../../db';
import { eq, ilike, count } from 'drizzle-orm';
import { categories, reports } from '../../db/schema';

export const categoryController = new Elysia({ prefix: '/categories' })
    // Get all categories
    .get('/', async () => {
        try {
            const allCategories = await db.select().from(categories).orderBy(categories.id);
            return {
                status: 'success',
                data: allCategories,
            };
        } catch (e) {
            console.error('Error fetching categories:', e);
            return { status: 'error', message: 'Internal Server Error' };
        }
    })

    // Create new category
    .post('/', async ({ body }) => {
        try {
            const newCategory = await db.insert(categories).values({
                name: body.name,
                type: 'non-emergency', // Default type
                icon: body.icon,
                description: 'Kategori kustom',
            }).returning();

            return {
                status: 'success',
                data: newCategory[0],
            };
        } catch (e) {
            console.error('Error creating category:', e);
            return { status: 'error', message: 'Failed to create category' };
        }
    }, {
        body: t.Object({
            name: t.String({ maxLength: 20 }), // Validate max length here too
            icon: t.String(),
        })
    })

    // Update category
    .put('/:id', async ({ params, body }) => {
        try {
            const id = parseInt(params.id);
            const updated = await db.update(categories)
                .set({
                    name: body.name,
                    icon: body.icon,
                })
                .where(eq(categories.id, id))
                .returning();

            if (updated.length === 0) {
                return { status: 'error', message: 'Category not found' };
            }

            return {
                status: 'success',
                data: updated[0],
            };
        } catch (e) {
            console.error('Error updating category:', e);
            return { status: 'error', message: 'Failed to update category' };
        }
    }, {
        body: t.Object({
            name: t.String({ maxLength: 20 }),
            icon: t.String(),
        })
    })

    // Delete category
    .delete('/:id', async ({ params }) => {
        try {
            const id = parseInt(params.id);

            // 1. Check if category exists
            const existing = await db.select().from(categories).where(eq(categories.id, id)).limit(1);
            if (existing.length === 0) {
                return { status: 'error', message: 'Category not found' };
            }

            // 1.5 Check if category is used in reports
            const usage = await db.select({ count: count() })
                .from(reports)
                .where(eq(reports.categoryId, id));

            if (usage[0].count > 0) {
                return {
                    status: 'error',
                    message: `Gagal menghapus. Kategori ini digunakan dalam ${usage[0].count} laporan.`
                };
            }

            // 2. Protect "Lainnya"
            if (existing[0].name.toLowerCase() === 'lainnya') {
                return { status: 'error', message: 'Kategori "Lainnya" tidak boleh dihapus!' };
            }

            // 3. Delete
            await db.delete(categories).where(eq(categories.id, id));

            return {
                status: 'success',
                message: 'Category deleted successfully',
            };
        } catch (e) {
            console.error('Error deleting category:', e);
            // Likely foreign key constraint if reports exist
            return {
                status: 'error',
                message: 'Gagal menghapus. Kategori ini mungkin sedang digunakan oleh laporan.'
            };
        }
    });
