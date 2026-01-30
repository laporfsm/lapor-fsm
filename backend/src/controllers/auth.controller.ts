import { Elysia, t } from 'elysia';
import { db } from '../db';
import { users, staff } from '../db/schema';
import { eq, or } from 'drizzle-orm';
import { jwt } from '@elysiajs/jwt';
import { mapToMobileUser } from '../utils/mapper';

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

    if (!user[0].isActive) {
      set.status = 403;
      return { status: 'error', message: 'Akun Anda telah dinonaktifkan. Silakan hubungi admin.' };
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
        user: mapToMobileUser(user[0]),
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

      if (body.phone === body.emergencyPhone) {
        set.status = 400;
        return { status: 'error', message: 'Nomor kontak darurat tidak boleh sama dengan nomor HP Anda' };
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
        faculty: body.faculty,
        address: body.address,
        emergencyName: body.emergencyName,
        emergencyPhone: body.emergencyPhone,
        idCardUrl: body.idCardUrl,
        isVerified: isUndip, // Auto-verify if UNDIP email
      }).returning();

      return {
        status: 'success',
        message: isUndip ? 'Registrasi berhasil' : 'Registrasi berhasil, menunggu verifikasi admin',
        data: {
          user: mapToMobileUser(newUser[0]),
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
      faculty: t.Optional(t.String()),
      address: t.Optional(t.String()),
      emergencyName: t.Optional(t.String()),
      emergencyPhone: t.Optional(t.String()),
      idCardUrl: t.Optional(t.String()),
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
        user: mapToMobileUser(foundStaff[0]),
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

  // Update Profile (Pelapor)
  .patch('/profile/:id', async ({ params, body }) => {
    const userId = parseInt(params.id);
    const updateData: any = {};

    if (body.name) updateData.name = body.name;
    if (body.phone) updateData.phone = body.phone;
    if (body.department) updateData.department = body.department;
    if (body.faculty) updateData.faculty = body.faculty;
    if (body.nimNip) updateData.nimNip = body.nimNip;
    if (body.address) updateData.address = body.address;
    if (body.emergencyName) updateData.emergencyName = body.emergencyName;
    if (body.emergencyPhone) updateData.emergencyPhone = body.emergencyPhone;

    const updated = await db
      .update(users)
      .set(updateData)
      .where(eq(users.id, userId))
      .returning();

    if (updated.length === 0) {
      return { status: 'error', message: 'User not found' };
    }

    return {
      status: 'success',
      message: 'Profil berhasil diperbarui',
      data: mapToMobileUser(updated[0]),
    };
  }, {
    body: t.Object({
      name: t.Optional(t.String()),
      phone: t.Optional(t.String()),
      department: t.Optional(t.String()),
      faculty: t.Optional(t.String()),
      nimNip: t.Optional(t.String()),
      address: t.Optional(t.String()),
      emergencyName: t.Optional(t.String()),
      emergencyPhone: t.Optional(t.String()),
    }),
  })

  // Update Profile (Staff)
  .patch('/staff-profile/:id', async ({ params, body }) => {
    const staffId = parseInt(params.id);
    const updateData: any = {};

    if (body.phone) updateData.phone = body.phone;
    if (body.specialization) updateData.specialization = body.specialization;
    if (body.name) updateData.name = body.name;

    const updated = await db
      .update(staff)
      .set(updateData)
      .where(eq(staff.id, staffId))
      .returning();

    if (updated.length === 0) {
      return { status: 'error', message: 'Staff not found' };
    }

    return {
      status: 'success',
      message: 'Profil staff berhasil diperbarui',
      data: mapToMobileUser(updated[0]),
    };
  }, {
    body: t.Object({
      name: t.Optional(t.String()),
      phone: t.Optional(t.String()),
      specialization: t.Optional(t.String()),
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
  })

  // Change Password (Common for both User and Staff)
  .post('/change-password', async ({ body, set }) => {
    const { id, role, oldPassword, newPassword } = body;
    const targetTable = role === 'pelapor' ? users : staff;

    const accounts = await db
      .select()
      .from(targetTable)
      .where(eq(targetTable.id, id))
      .limit(1);

    if (accounts.length === 0) {
      set.status = 404;
      return { status: 'error', message: 'Akun tidak ditemukan' };
    }

    const isMatch = await Bun.password.verify(oldPassword, accounts[0].password);
    if (!isMatch) {
      set.status = 400;
      return { status: 'error', message: 'Password lama salah' };
    }

    const newHashedPassword = await Bun.password.hash(newPassword);
    await db
      .update(targetTable)
      .set({ password: newHashedPassword })
      .where(eq(targetTable.id, id));

    return {
      status: 'success',
      message: 'Password berhasil diubah'
    };
  }, {
    body: t.Object({
      id: t.Number(),
      role: t.Enum({ pelapor: 'pelapor', teknisi: 'teknisi', supervisor: 'supervisor', admin: 'admin', pj_gedung: 'pj_gedung' }),
      oldPassword: t.String(),
      newPassword: t.String(),
    })
  });
