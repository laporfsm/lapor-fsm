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
  // User Login (Pelapor)
  .post('/login', async ({ body, jwt, set }) => {
    const user = await db
      .select()
      .from(users)
      .where(eq(users.email, body.email))
      .limit(1);

    if (user.length === 0) {
      set.status = 401;
      return { status: 'error', message: 'Email atau password salah' };
    }

    const isPasswordCorrect = await Bun.password.verify(body.password, user[0].password);
    
    if (!isPasswordCorrect) {
      set.status = 401;
      return { status: 'error', message: 'Email atau password salah' };
    }

    if (!user[0].isVerified && !body.email.endsWith('@undip.ac.id') && !body.email.endsWith('.undip.ac.id')) {
        set.status = 403;
        return { status: 'error', message: 'Akun Anda sedang menunggu verifikasi admin' };
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
        user: {
          ...user[0],
          id: user[0].id.toString(),
          password: '', // Don't send password back
        },
        token,
        role: 'pelapor'
      },
    };
  }, {
    body: t.Object({
      email: t.String(),
      password: t.String(),
    }),
  })

  // User Registration (Pelapor)
  .post('/register', async ({ body, set }) => {
      try {
          // Check if email already exists
          const existing = await db.select().from(users).where(eq(users.email, body.email)).limit(1);
          if (existing.length > 0) {
              set.status = 400;
              return { status: 'error', message: 'Email sudah terdaftar' };
          }

          const isUndip = body.email.toLowerCase().endsWith('@undip.ac.id') || 
                          body.email.toLowerCase().endsWith('.undip.ac.id');
          
          const hashedPassword = await Bun.password.hash(body.password);

          const newUser = await db.insert(users).values({
              name: body.name,
              email: body.email,
              password: hashedPassword,
              phone: body.phone,
              nimNip: body.nimNip,
              department: body.department,
              address: body.address,
              emergencyName: body.emergencyName,
              emergencyPhone: body.emergencyPhone,
              isVerified: isUndip, // Auto-verify if UNDIP email
          }).returning();

          return {
              status: 'success',
              message: isUndip ? 'Registrasi berhasil' : 'Registrasi berhasil, menunggu verifikasi admin',
              data: {
                  user: {
                      ...newUser[0],
                      id: newUser[0].id.toString(),
                      password: '',
                  },
                  needsApproval: !isUndip
              }
          };
      } catch (error: any) {
          set.status = 500;
          return { status: 'error', message: error.message };
      }
  }, {
      body: t.Object({
          name: t.String(),
          email: t.String(),
          password: t.String(),
          phone: t.String(),
          nimNip: t.String(),
          department: t.Optional(t.String()),
          address: t.Optional(t.String()),
          emergencyName: t.Optional(t.String()),
          emergencyPhone: t.Optional(t.String()),
      })
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
          id: foundStaff[0].id.toString(),
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

  // Register Phone Number (Update Profile)
  .post('/register-phone', async ({ body }) => {
    const updated = await db
      .update(users)
      .set({ phone: body.phone, department: body.department })
      .where(eq(users.id, Number(body.userId)))
      .returning();

    if (updated.length === 0) {
      return { status: 'error', message: 'User not found' };
    }

    return {
      status: 'success',
      message: 'Profil berhasil diperbarui',
      data: {
        ...updated[0],
        id: updated[0].id.toString(),
        password: '',
      },
    };
  }, {
    body: t.Object({
      userId: t.String(),
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
