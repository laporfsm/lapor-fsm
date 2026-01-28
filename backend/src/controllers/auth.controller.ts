import { Elysia, t } from 'elysia';
import { db } from '../db';
import { users, staff } from '../db/schema';
import { eq, or } from 'drizzle-orm';
import { jwt } from '@elysiajs/jwt';

export const authController = new Elysia({ prefix: '/auth' })
  .use(
    jwt({
      name: 'jwt',
      secret: process.env.JWT_SECRET || 'lapor-fsm-secret-key-change-in-production'
    })
  )
  // User Login (SSO Mock)
  .post('/login', async ({ body, jwt }) => {
    let user = await db
      .select()
      .from(users)
      .where(eq(users.email, body.email))
      .limit(1);

    if (user.length === 0) {
      const newUser = await db.insert(users).values({
        ssoId: body.ssoId || `SSO-${Date.now()}`,
        name: body.name,
        email: body.email,
        faculty: 'Sains dan Matematika',
      }).returning();
      
      user = newUser;
    }

    const token = await jwt.sign({
      id: user[0].id,
      role: 'pelapor',
      email: user[0].email
    });

    return {
      status: 'success',
      message: 'Login berhasil',
      data: {
        user: user[0],
        token,
        needsPhone: !user[0].phone,
        role: 'pelapor'
      },
    };
  }, {
    body: t.Object({
      email: t.String(),
      name: t.String(),
      ssoId: t.Optional(t.String()),
    }),
  })

  // Staff Login (Email & Password)
  .post('/staff-login', async ({ body, jwt, set }) => {
    const foundStaff = await db
      .select()
      .from(staff)
      .where(eq(staff.email, body.email))
      .limit(1);

    if (foundStaff.length === 0) {
      set.status = 401;
      return { status: 'error', message: 'Email atau password salah' };
    }

    const isPasswordCorrect = await Bun.password.verify(body.password, foundStaff[0].password);
    
    if (!isPasswordCorrect) {
      set.status = 401;
      return { status: 'error', message: 'Email atau password salah' };
    }

    const token = await jwt.sign({
      id: foundStaff[0].id,
      role: foundStaff[0].role,
      email: foundStaff[0].email
    });

    return {
      status: 'success',
      message: 'Staff login berhasil',
      data: {
        user: {
          id: foundStaff[0].id,
          name: foundStaff[0].name,
          email: foundStaff[0].email,
          role: foundStaff[0].role,
          phone: foundStaff[0].phone
        },
        token,
        role: foundStaff[0].role
      },
    };
  }, {
    body: t.Object({
      email: t.String(),
      password: t.String(),
    }),
  })

  // Register Phone Number for Pelapor
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

  // Verify Token
  .get('/verify', async ({ headers, jwt, set }) => {
    const authHeader = headers['authorization'];
    if (!authHeader?.startsWith('Bearer ')) {
      set.status = 401;
      return { status: 'error', message: 'Unauthorized' };
    }

    const token = authHeader.split(' ')[1];
    const payload = await jwt.verify(token);

    if (!payload) {
      set.status = 401;
      return { status: 'error', message: 'Invalid or expired token' };
    }

    return {
      status: 'success',
      data: payload
    };
  });
