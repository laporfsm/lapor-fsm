import { Elysia, t } from 'elysia';
import { db } from '../db';
import { users } from '../db/schema';
import { eq } from 'drizzle-orm';

export const authController = new Elysia({ prefix: '/auth' })
  // Mock SSO Login
  .post('/login', async ({ body }) => {
    // In production, this would validate against SSO Undip
    // For now, create or get user by email
    
    let user = await db
      .select()
      .from(users)
      .where(eq(users.email, body.email))
      .limit(1);

    if (user.length === 0) {
      // Create new user
      const newUser = await db.insert(users).values({
        ssoId: body.ssoId || `SSO-${Date.now()}`,
        name: body.name,
        email: body.email,
        faculty: 'Sains dan Matematika',
      }).returning();
      
      user = newUser;
    }

    return {
      status: 'success',
      message: 'Login berhasil',
      data: {
        user: user[0],
        token: `mock-jwt-token-${user[0].id}`, // In production, use real JWT
        needsPhone: !user[0].phone,
      },
    };
  }, {
    body: t.Object({
      email: t.String(),
      name: t.String(),
      ssoId: t.Optional(t.String()),
    }),
  })

  // Register Phone Number
  .post('/register-phone', async ({ body }) => {
    const updated = await db
      .update(users)
      .set({ phone: body.phone, department: body.department })
      .where(eq(users.id, body.userId))
      .returning();

    if (updated.length === 0) {
      return { status: 'error', message: 'User not found' };
    }

    return {
      status: 'success',
      message: 'Nomor HP berhasil disimpan',
      data: updated[0],
    };
  }, {
    body: t.Object({
      userId: t.Number(),
      phone: t.String(),
      department: t.Optional(t.String()),
    }),
  })

  // Get Current User
  .get('/me/:userId', async ({ params }) => {
    const user = await db
      .select()
      .from(users)
      .where(eq(users.id, parseInt(params.userId)))
      .limit(1);

    if (user.length === 0) {
      return { status: 'error', message: 'User not found' };
    }

    return {
      status: 'success',
      data: user[0],
    };
  });
