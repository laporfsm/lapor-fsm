import { Elysia, t } from 'elysia';
import { db } from '../db';
import { users, staff, reportLogs } from '../db/schema';
import { eq, or } from 'drizzle-orm';
import { jwt } from '@elysiajs/jwt';
import { mapToMobileUser } from '../utils/mapper';
import { NotificationService } from '../services/notification.service';
import { EmailService } from '../services/email.service';

export const authController = new Elysia({ prefix: '/auth' })
  .use(
    jwt({
      name: 'jwt',
      secret: process.env.JWT_SECRET || 'lapor-fsm-secret-key-change-in-production'
    })
  )
  // User Login (Pelapor)
  .post('/login', async ({ body, jwt, set }) => {
    const foundUser = await db.select().from(users).where(eq(users.email, body.email)).limit(1);
    if (foundUser.length === 0) {
      set.status = 401;
      return { status: 'error', message: 'Email atau password salah' };
    }

    const isMatch = await Bun.password.verify(body.password, foundUser[0].password);
    if (!isMatch) {
      set.status = 401;
      return { status: 'error', message: 'Email atau password salah' };
    }

    if (!foundUser[0].isActive) {
      set.status = 403;
      return { status: 'error', message: 'Akun Anda dinonaktifkan. Silakan hubungi admin.' };
    }

    if (!foundUser[0].isEmailVerified) {
      set.status = 403;
      return { status: 'error', message: 'Email belum diverifikasi. Silakan verifikasi email Anda terlebih dahulu.' };
    }

    if (!foundUser[0].isVerified) {
      set.status = 403;
      return { status: 'error', message: 'Akun Anda sedang menunggu verifikasi oleh admin.' };
    }

    // Sign JWT
    const token = await jwt.sign({
      id: foundUser[0].id,
      role: 'pelapor',
      email: foundUser[0].email
    });

    return {
      status: 'success',
      message: 'Login berhasil',
      data: {
        user: mapToMobileUser(foundUser[0]),
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

      const hashedPassword = await Bun.password.hash(body.password);
      const verificationToken = Math.floor(100000 + Math.random() * 900000).toString();

      const expiresAt = new Date();
      expiresAt.setMinutes(expiresAt.getMinutes() + 15);

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
        isVerified: false, // Always false now, requires admin approval
        isEmailVerified: false,
        emailVerificationToken: verificationToken,
        emailVerificationExpiresAt: expiresAt,
      }).returning();

      // Log registration
      await db.insert(reportLogs).values({
        action: 'register',
        actorId: newUser[0].id.toString(),
        actorName: newUser[0].name,
        actorRole: 'user',
        reason: 'User mendaftar ke sistem',
      });

      // Notify Admins
      await NotificationService.notifyRole('admin', 'Request Registrasi Baru', `User baru ${newUser[0].name} telah mendaftar dan menunggu verifikasi email.`);

      // In-memory log still useful for dev if email fails
      console.log(`[AUTH] Verification token for ${body.email}: ${verificationToken}`);

      // Send Real Email
      try {
        // Fire and forget - don't block response on email sending unless critical
        EmailService.sendVerificationEmail(body.email, body.name, verificationToken);
      } catch (err) {
        console.error('[AUTH] Background email send failed:', err);
      }

      return {
        status: 'success',
        message: 'Registrasi berhasil. Kode verifikasi telah dikirim ke email Anda.',
        data: {
          user: mapToMobileUser(newUser[0]),
          needsEmailVerification: true,
          needsAdminApproval: true
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

  // Verify Email
  .post('/verify-email', async ({ body, set }) => {
    const { email, token } = body;
    const user = await db.select().from(users).where(eq(users.email, email)).limit(1);

    if (user.length === 0) {
      set.status = 404;
      return { status: 'error', message: 'User tidak ditemukan' };
    }

    // ... existing logic ...

    // (Optimization: cleaned up for brevity in tool call, sticking to adding new endpoint below)
    if (user[0].isEmailVerified) {
      return { status: 'success', message: 'Email sudah diverifikasi sebelumnya.' };
    }

    if (user[0].emailVerificationToken !== token) {
      set.status = 400;
      return { status: 'error', message: 'Kode verifikasi tidak valid' };
    }

    if (user[0].emailVerificationExpiresAt && new Date() > new Date(user[0].emailVerificationExpiresAt)) {
      set.status = 400;
      return { status: 'error', message: 'Kode verifikasi telah kedaluwarsa. Silakan minta kode baru.' };
    }

    await db.update(users)
      .set({ isEmailVerified: true, emailVerificationToken: null, emailVerificationExpiresAt: null })
      .where(eq(users.id, user[0].id));

    // Log email verification
    await db.insert(reportLogs).values({
      action: 'verify_email',
      actorId: user[0].id.toString(),
      actorName: user[0].name,
      actorRole: 'user',
      reason: 'User memverifikasi email',
    });

    // Notify Admins for Approval
    await NotificationService.notifyRole('admin', 'User Siap Diverifikasi', `User ${user[0].name} telah memverifikasi email dan menunggu persetujuan admin.`);

    return {
      status: 'success',
      message: 'Email berhasil diverifikasi. Silakan tunggu persetujuan admin.'
    };
  }, {
    body: t.Object({
      email: t.String(),
      token: t.String(),
    })
  })

  // Resend Verification Code
  .post('/resend-verification', async ({ body, set }) => {
    const { email } = body;
    const user = await db.select().from(users).where(eq(users.email, email)).limit(1);

    if (user.length === 0) {
      set.status = 404;
      return { status: 'error', message: 'User tidak ditemukan' };
    }

    if (user[0].isEmailVerified) {
      return { status: 'success', message: 'Email akun ini sudah terverifikasi.' };
    }

    // Generate new token
    const verificationToken = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 15);

    await db.update(users)
      .set({
        emailVerificationToken: verificationToken,
        emailVerificationExpiresAt: expiresAt
      })
      .where(eq(users.id, user[0].id));

    // In a real app, send actual email here
    console.log(`[AUTH] Resent Verification token for ${email}: ${verificationToken}`);

    // Send Real Email
    try {
      EmailService.sendVerificationEmail(email, user[0].name, verificationToken);
    } catch (err) {
      console.error('[AUTH] Background email send failed:', err);
    }

    return {
      status: 'success',
      message: 'Kode verifikasi baru telah dikirim ke email Anda.'
    };
  }, {
    body: t.Object({
      email: t.String()
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
      email: foundStaff[0].email,
      managedBuilding: foundStaff[0].managedBuilding,
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
    if (body.address !== undefined) updateData.address = body.address;
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
      address: t.Optional(t.String()),
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
