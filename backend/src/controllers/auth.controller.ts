import { Elysia, t } from 'elysia';
import { db } from '../db';
import { users, staff, reportLogs } from '../db/schema';
import { eq, or } from 'drizzle-orm';
import { jwt } from '@elysiajs/jwt';
import { mapToMobileUser } from '../utils/mapper';
import { NotificationService } from '../services/notification.service';
import { EmailService } from '../services/email.service';
import { resolve } from 'node:path';

let resetPasswordLogoCache: string | null = null;

const getResetPasswordLogo = async (): Promise<string> => {
  if (resetPasswordLogoCache !== null) return resetPasswordLogoCache;

  const candidatePaths = [
    resolve(process.cwd(), '../mobile/assets/images/logo.png'),
    resolve(process.cwd(), 'mobile/assets/images/logo.png'),
  ];

  for (const candidatePath of candidatePaths) {
    const file = Bun.file(candidatePath);
    if (await file.exists()) {
      const buffer = Buffer.from(await file.arrayBuffer());
      resetPasswordLogoCache = `data:image/png;base64,${buffer.toString('base64')}`;
      return resetPasswordLogoCache;
    }
  }

  resetPasswordLogoCache = '';
  return resetPasswordLogoCache;
};

export const authController = new Elysia({ prefix: '/auth' })
  .use(
    jwt({
      name: 'jwt',
      secret: process.env.JWT_SECRET || 'lapor-fsm-secret-key-change-in-production'
    })
  )
  // User Login (Pelapor)
  .post('/login', async ({ body, jwt, set }) => {
    console.log('[LOGIN] Attempting login for:', body.email);
    const foundUser = await db.select().from(users).where(eq(users.email, body.email)).limit(1);
    if (foundUser.length === 0) {
      console.log('[LOGIN] User not found');
      set.status = 401;
      return { status: 'error', message: 'Email atau password salah' };
    }

    console.log('[LOGIN] User found. Verifying password...');
    // Debug: Log first few chars of stored hash (safe to log hash header usually)
    console.log('[LOGIN] Stored hash start:', foundUser[0].password.substring(0, 10) + '...');

    const isMatch = await Bun.password.verify(body.password, foundUser[0].password);
    console.log('[LOGIN] Password match result:', isMatch);

    if (!isMatch) {
      set.status = 401;
      return { status: 'error', message: 'Email atau password salah' };
    }

    console.log('[LOGIN] Checks passed. user.isActive:', foundUser[0].isActive);
    console.log('[LOGIN] Checks passed. user.isEmailVerified:', foundUser[0].isEmailVerified);
    console.log('[LOGIN] Checks passed. user.isVerified:', foundUser[0].isVerified);

    if (!foundUser[0].isActive) {
      set.status = 403;
      return { status: 'error', message: 'Akun Anda dinonaktifkan. Silakan hubungi admin.' };
    }

    if (!foundUser[0].isEmailVerified) {
      set.status = 403;
      return { status: 'error', message: 'Akun Anda belum diaktivasi. Silakan cek email Anda dan klik link aktivasi.' };
    }

    if (!foundUser[0].isVerified) {
      set.status = 403;
      return { status: 'error', message: 'Akun Anda sedang menunggu persetujuan admin.' };
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
      const isUndipEmail = (email: string) => {
        const lowerEmail = email.toLowerCase();
        // Only @students.undip.ac.id gets auto-verified flow
        // @live.undip.ac.id and other emails go to external email flow (require ID card and admin approval)
        return lowerEmail.endsWith('@students.undip.ac.id');
      };

      // Validation
      if (!body.email.includes('@')) {
        set.status = 400;
        return { status: 'error', message: 'Format email tidak valid' };
      }

      if (body.password.length < 6) {
        set.status = 400;
        return { status: 'error', message: 'Password minimal 6 karakter' };
      }

      // Check if email already exists
      const existing = await db.select().from(users).where(eq(users.email, body.email)).limit(1);
      if (existing.length > 0) {
        set.status = 400;
        return { status: 'error', message: 'Email sudah terdaftar' };
      }

      // Requirements for Non-UNDIP emails
      if (!isUndipEmail(body.email) && !body.idCardUrl) {
        set.status = 400;
        return { status: 'error', message: 'Kartu identitas wajib diunggah untuk email selain UNDIP' };
      }

      if (body.phone === body.emergencyPhone) {
        set.status = 400;
        return { status: 'error', message: 'Nomor kontak darurat tidak boleh sama dengan nomor HP Anda' };
      }

      const hashedPassword = await Bun.password.hash(body.password);

      const isUndip = isUndipEmail(body.email);

      const crypto = require('crypto');

      let activationToken = null;
      let expiresAt = null;

      // For UNDIP: generate token for email activation
      // For External: no token yet, will be generated after admin approval
      if (isUndip) {
        activationToken = crypto.randomBytes(32).toString('hex');
        expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours
      }

      const newUser = await db.insert(users).values({
        name: body.name,
        email: body.email,
        password: hashedPassword,
        phone: body.phone,
        nimNip: body.nimNip,
        department: body.department,
        faculty: body.faculty || 'Sains dan Matematika',
        address: body.address,
        emergencyName: body.emergencyName,
        emergencyPhone: body.emergencyPhone,
        idCardUrl: body.idCardUrl,
        isVerified: isUndip, // UNDIP users are auto-verified, External users need admin approval
        isEmailVerified: false,
        emailVerificationToken: activationToken,
        emailVerificationExpiresAt: expiresAt,
      }).returning();

      // Log registration (non-blocking)
      try {
        await db.insert(reportLogs).values({
          action: 'register',
          actorId: newUser[0].id.toString(),
          actorName: newUser[0].name,
          actorRole: 'pelapor',
          reason: isUndip
            ? 'User mendaftar (UNDIP Email - Menunggu Aktivasi)'
            : 'User mendaftar (Non-UNDIP, Menunggu Approval Admin)',
        });
      } catch (logErr) {
        console.error('[REGISTER] Log insertion failed (non-critical):', logErr);
      }

      // Notify Admins for non-UNDIP
      if (!isUndip) {
        await NotificationService.notifyRole(
          'admin',
          'Request Registrasi Baru',
          `User baru ${newUser[0].name} (${body.email}) telah mendaftar dan menunggu approval.`
        );
      }

      // Send activation email only for UNDIP users
      if (isUndip) {
        const apiUrl = process.env.API_URL || 'http://localhost:3000';
        const activationLink = `${apiUrl}/auth/activate?token=${activationToken}&email=${encodeURIComponent(body.email)}`;

        console.log(`[AUTH] Activation token for ${body.email}: ${activationToken}`);
        try {
          EmailService.sendActivationEmail(body.email, body.name, activationLink, isUndip);
        } catch (err) {
          console.error('[AUTH] Background activation email send failed:', err);
        }
      }

      return {
        status: 'success',
        message: isUndip
          ? 'Registrasi berhasil. Silakan cek email Anda untuk mengaktifkan akun.'
          : 'Registrasi berhasil. Akun Anda sedang menunggu persetujuan admin.',
        data: {
          user: mapToMobileUser(newUser[0]),
          needsEmailVerification: isUndip,
          needsAdminApproval: !isUndip,
          isUndip: isUndip
        }
      };
    } catch (error: any) {
      console.error(' [REGISTRATION ERROR] ', error);
      set.status = 500;

      // Return more specific message if available
      const errorMessage = error?.message || 'Internal server error';
      return {
        status: 'error',
        message: `Terjadi kesalahan pada server: ${errorMessage}. Pastikan konfigurasi SMTP dan Database sudah benar.`
      };
    }
  }, {
    body: t.Object({
      name: t.String({ minLength: 2 }),
      email: t.String(),
      password: t.String({ minLength: 6 }),
      phone: t.String(),
      nimNip: t.String(),
      department: t.Optional(t.String()),
      faculty: t.Optional(t.String()),
      address: t.Optional(t.String()),
      emergencyName: t.Optional(t.String()),
      emergencyPhone: t.Optional(t.String()),
      idCardUrl: t.Optional(t.Nullable(t.String())),
    })
  })

  // Activate Account (for both UNDIP and External after approval)
  .get('/activate', async ({ query, set }) => {
    const { token, email } = query;

    console.log(`[ACTIVATE] Activation attempt for email: ${email}`);

    const user = await db.select().from(users).where(eq(users.email, email)).limit(1);

    if (user.length === 0) {
      set.status = 404;
      return '<html><body><h1>Akun Tidak Ditemukan</h1><p>Email tidak terdaftar.</p></body></html>';
    }

    if (user[0].isEmailVerified) {
      set.headers['Content-Type'] = 'text/html';
      return `
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Akun Sudah Aktif - Lapor FSM</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; justify-content: center; align-items: center; padding: 20px; }
        .container { background: white; border-radius: 20px; padding: 40px; max-width: 500px; width: 100%; text-align: center; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
        .icon { width: 80px; height: 80px; background: #3b82f6; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px; }
        .icon svg { width: 40px; height: 40px; fill: white; }
        h1 { color: #1f2937; font-size: 24px; margin-bottom: 16px; font-weight: 700; }
        p { color: #6b7280; font-size: 16px; line-height: 1.6; margin-bottom: 24px; }
        .btn { display: inline-block; background: #3b82f6; color: white; text-decoration: none; padding: 14px 32px; border-radius: 10px; font-weight: 600; font-size: 16px; transition: all 0.3s; }
        .btn:hover { background: #2563eb; transform: translateY(-2px); box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4); }
        .note { color: #9ca3af; font-size: 13px; margin-top: 16px; }
        .footer { margin-top: 32px; padding-top: 24px; border-top: 1px solid #e5e7eb; color: #9ca3af; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">
            <svg viewBox="0 0 24 24"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>
        </div>
        <h1>Akun Sudah Aktif</h1>
        <p>Akun Anda sudah aktif sebelumnya. Silakan buka aplikasi dan login.</p>
        <a href="laporfsm://login" class="btn">Buka Aplikasi</a>
        <p class="note">Jika tombol tidak bekerja, buka aplikasi Lapor FSM secara manual.</p>
        <div class="footer">Lapor FSM - Fakultas Sains dan Matematika<br>Universitas Diponegoro</div>
    </div>
</body>
</html>`;
    }

    if (user[0].emailVerificationToken !== token) {
      set.status = 400;
      return '<html><body><h1>Token Tidak Valid</h1><p>Link aktivasi tidak valid.</p></body></html>';
    }

    if (user[0].emailVerificationExpiresAt && new Date() > new Date(user[0].emailVerificationExpiresAt)) {
      set.status = 400;
      return '<html><body><h1>Link Kadaluwarsa</h1><p>Link aktivasi telah kedaluwarsa.</p></body></html>';
    }

    const isUndip = email.endsWith('@students.undip.ac.id') || email.endsWith('@lecturers.undip.ac.id') || email.endsWith('@staff.undip.ac.id');

    // Activate immediately
    await db.update(users)
      .set({
        isEmailVerified: true,
        emailVerificationToken: null,
        emailVerificationExpiresAt: null
      })
      .where(eq(users.id, user[0].id));

    console.log(`[ACTIVATE] User ${user[0].id} activated successfully`);

    // Log activation (non-blocking)
    try {
      await db.insert(reportLogs).values({
        action: 'activate_account',
        actorId: user[0].id.toString(),
        actorName: user[0].name,
        actorRole: 'pelapor',
        reason: isUndip ? 'User UNDIP mengaktifkan akun' : 'User External verifikasi email',
      });
    } catch (logErr) {
      console.error('[ACTIVATE] Log insertion failed (non-critical):', logErr);
    }

    // Notify admin for non-UNDIP
    if (!isUndip) {
      try {
        await NotificationService.notifyRole('admin', 'User Siap Diverifikasi', `User ${user[0].name} (${user[0].email}) telah verifikasi email dan menunggu persetujuan admin.`);
      } catch (err) {
        console.error('[ACTIVATE] Failed to notify admin:', err);
      }
    }

    const loginUrl = 'laporfsm://login';

    set.headers['Content-Type'] = 'text/html';
    return `
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aktivasi Akun - Lapor FSM</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; justify-content: center; align-items: center; padding: 20px; }
        .container { background: white; border-radius: 20px; padding: 40px; max-width: 500px; width: 100%; text-align: center; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
        .icon { width: 80px; height: 80px; background: #10b981; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px; }
        .icon svg { width: 40px; height: 40px; fill: white; }
        h1 { color: #1f2937; font-size: 24px; margin-bottom: 16px; font-weight: 700; }
        p { color: #6b7280; font-size: 16px; line-height: 1.6; margin-bottom: 24px; }
        .btn { display: inline-block; background: #3b82f6; color: white; text-decoration: none; padding: 14px 32px; border-radius: 10px; font-weight: 600; font-size: 16px; transition: all 0.3s; }
        .btn:hover { background: #2563eb; transform: translateY(-2px); box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4); }
        .footer { margin-top: 32px; padding-top: 24px; border-top: 1px solid #e5e7eb; color: #9ca3af; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">
            <svg viewBox="0 0 24 24"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>
        </div>
        <h1>Akun Anda Telah Aktif!</h1>
        <p>Selamat! Akun Lapor FSM Anda telah berhasil diaktivasi. Anda sekarang dapat login dan mulai menggunakan aplikasi.</p>
        <a href="${loginUrl}" class="btn">Buka Aplikasi</a>
        <p style="color: #9ca3af; font-size: 13px; margin-top: 16px;">Jika tombol tidak bekerja, buka aplikasi Lapor FSM secara manual.</p>
        <div class="footer">Lapor FSM - Fakultas Sains dan Matematika<br>Universitas Diponegoro</div>
    </div>
</body>
</html>`;
  }, {
    query: t.Object({
      token: t.String(),
      email: t.String(),
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

  // Forgot Password - Send reset link
  .post('/forgot-password', async ({ body, set }) => {
    const { email } = body;
    console.log('[FORGOT PASSWORD] Receiving request for:', email);

    const user = await db.select().from(users).where(eq(users.email, email)).limit(1);
    const staffUser = user.length === 0
      ? await db.select().from(staff).where(eq(staff.email, email)).limit(1)
      : [];

    if (user.length === 0 && staffUser.length === 0) {
      console.log('[FORGOT PASSWORD] User NOT found (returning 404):', email);
      set.status = 404;
      return {
        status: 'error',
        message: 'Email tidak terdaftar dalam sistem.'
      };
    }

    // Generate reset token
    const crypto = require('crypto');
    const resetToken = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 1); // 1 hour expiry

    const isStaffAccount = staffUser.length > 0;
    const accountName = isStaffAccount ? staffUser[0].name : user[0].name;

    if (isStaffAccount) {
      await db.update(staff)
        .set({
          passwordResetToken: resetToken,
          passwordResetExpiresAt: expiresAt
        })
        .where(eq(staff.id, staffUser[0].id));
    } else {
      await db.update(users)
        .set({
          passwordResetToken: resetToken,
          passwordResetExpiresAt: expiresAt
        })
        .where(eq(users.id, user[0].id));
    }

    // Construct reset link (using API URL instead of App URL to hit our bridge page)
    const apiUrl = process.env.API_URL || 'http://localhost:3000';
    const resetLink = `${apiUrl}/auth/reset-password?token=${resetToken}&email=${encodeURIComponent(email)}`;

    // Send email
    try {
      await EmailService.sendPasswordResetEmail(email, accountName, resetLink);
    } catch (err) {
      console.error('[AUTH] Failed to send password reset email:', err);
    }

    console.log(`[AUTH] Password reset token for ${email}: ${resetToken}`);

    return {
      status: 'success',
      message: 'Jika email terdaftar, link reset password akan dikirim.'
    };
  }, {
    body: t.Object({
      email: t.String()
    })
  })

  // Reset Password Web Page (web-first flow)
  .get('/reset-password', async ({ query, set }) => {
    const { token, email } = query;
    const encodedToken = encodeURIComponent(token);
    const encodedEmail = encodeURIComponent(email);
    const logoSrc = await getResetPasswordLogo();

    set.headers['Content-Type'] = 'text/html';
    return `
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Password - Lapor FSM</title>
    <style>
        :root {
          --primary: #1E3A8A;
          --primary-soft: #DBEAFE;
          --bg: #F3F4F6;
          --card: #FFFFFF;
          --text: #111827;
          --muted: #6B7280;
          --border: #D1D5DB;
          --radius: 12px;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: "Nunito Sans", "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
          color: var(--text);
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 20px;
          background: linear-gradient(180deg, #f7f8fc 0%, #eef2f8 100%);
        }
        .container {
          width: 100%;
          max-width: 510px;
          background: var(--card);
          border-radius: 24px;
          border: 1px solid #dde5f5;
          padding: 28px 24px 22px;
          box-shadow: 0 18px 40px rgba(18, 37, 82, 0.11);
        }
        .brand {
          display: flex;
          justify-content: center;
          margin-bottom: 16px;
        }
        .brand-logo {
          width: 94px;
          height: auto;
          border-radius: 10px;
          box-shadow: 0 6px 18px rgba(11, 31, 82, 0.12);
        }
        .hero-icon {
          width: 104px;
          height: 104px;
          margin: 0 auto 20px;
          border-radius: 999px;
          background: rgba(30, 58, 138, 0.1);
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .hero-icon svg { width: 50px; height: 50px; fill: var(--primary); }
        h1 {
          color: #0F172A;
          text-align: center;
          font-size: 30px;
          font-weight: 800;
          letter-spacing: -0.02em;
          margin-bottom: 8px;
        }
        .subtitle {
          color: var(--muted);
          text-align: center;
          font-size: 14px;
          line-height: 1.55;
          margin-bottom: 24px;
        }
        .card {
          border: 0;
          border-radius: 0;
          background: transparent;
          padding: 0;
          transition: all 0.2s ease;
        }
        .card.success-state {
          background: #ECFDF5;
          border-color: #86EFAC;
        }
        .field { margin-bottom: 14px; }
        .field label {
          display: block;
          margin-bottom: 6px;
          color: #374151;
          font-size: 15px;
          font-weight: 700;
        }
        .input-wrap {
          display: flex;
          align-items: center;
          border: 1.5px solid #b5c4eb;
          border-radius: 18px;
          background: #FFFFFF;
          min-height: 60px;
          transition: border-color 0.15s ease, box-shadow 0.15s ease;
        }
        .input-wrap:focus-within {
          border-color: var(--primary);
          box-shadow: 0 0 0 4px rgba(30, 58, 138, 0.14);
        }
        .input-wrap input {
          width: 100%;
          border: 0;
          outline: 0;
          background: transparent;
          padding: 15px 16px;
          color: #111827;
          font-size: 17px;
        }
        .toggle-visibility {
          border: 0;
          background: transparent;
          color: #6B7280;
          width: 48px;
          height: 48px;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          border-radius: 10px;
          margin-right: 4px;
        }
        .toggle-visibility:focus-visible {
          outline: 2px solid var(--primary);
          outline-offset: 1px;
        }
        .toggle-visibility svg { width: 22px; height: 22px; fill: currentColor; }
        .hint {
          color: #6B7280;
          font-size: 12px;
          margin-top: 6px;
        }
        .danger, .success {
          margin-top: 12px;
          padding: 10px 12px;
          border-radius: 10px;
          font-size: 13px;
          display: none;
        }
        .danger {
          color: #B91C1C;
          background: #FEF2F2;
          border: 1px solid #FECACA;
        }
        .success {
          color: #166534;
          background: #F0FDF4;
          border: 1px solid #BBF7D0;
        }
        .btn-primary {
          margin-top: 16px;
          width: 100%;
          border: 0;
          border-radius: 18px;
          background: var(--primary);
          color: #FFFFFF;
          padding: 16px 16px;
          font-size: 18px;
          font-weight: 700;
          cursor: pointer;
          transition: opacity 0.2s ease;
        }
        .btn-primary:disabled { opacity: 0.72; cursor: not-allowed; }
        .actions { margin-top: 14px; display: none; }
        .btn-open-app {
          display: inline-flex;
          width: 100%;
          text-decoration: none;
          align-items: center;
          justify-content: center;
          border-radius: 18px;
          background: var(--primary);
          color: #FFFFFF;
          font-size: 17px;
          font-weight: 700;
          padding: 16px 16px;
        }
        .hidden { display: none; }
        .footer {
          margin-top: 24px;
          padding-top: 16px;
          border-top: 1px solid #E5E7EB;
          color: #9CA3AF;
          font-size: 12px;
          line-height: 1.45;
          text-align: left;
        }
        @media (max-width: 480px) {
          body {
            padding: 0;
            display: block;
            background: #f3f4f6;
            min-height: 100dvh;
          }
          .container {
            max-width: 100%;
            min-height: 100dvh;
            margin: 0;
            border-radius: 0;
            padding: 26px 24px 24px;
            box-shadow: none;
            background: transparent;
            border: 0;
          }
          .brand { margin-bottom: 12px; }
          .brand-logo { width: 86px; }
          .hero-icon {
            width: 112px;
            height: 112px;
            margin-bottom: 20px;
          }
          .hero-icon svg { width: 52px; height: 52px; }
          h1 { font-size: 24px; margin-bottom: 10px; }
          .subtitle { font-size: 14px; margin-bottom: 26px; line-height: 1.55; }
          .card {
            padding: 0;
            border: 0;
            border-radius: 0;
            background: transparent;
          }
          .field { margin-bottom: 16px; }
          .field label { font-size: 16px; margin-bottom: 9px; }
          .input-wrap {
            border-radius: 22px;
            border-color: #a9bbe8;
          }
          .input-wrap input {
            font-size: 17px;
            padding: 16px 18px;
          }
          .toggle-visibility {
            width: 48px;
            height: 48px;
          }
          .toggle-visibility svg { width: 24px; height: 24px; }
          .hint { font-size: 13px; margin-top: 7px; }
          .btn-primary, .btn-open-app {
            font-size: 17px;
            border-radius: 20px;
            padding: 17px 16px;
            margin-top: 18px;
          }
          .danger, .success { font-size: 14px; }
          .footer {
            margin-top: 36px;
            font-size: 13px;
          }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="brand">
          ${logoSrc ? `<img src="${logoSrc}" alt="Logo Lapor FSM" class="brand-logo" />` : ''}
        </div>
        <div class="hero-icon">
          <svg viewBox="0 0 24 24"><path d="M12.65 10C11.83 7.67 9.61 6 7 6c-3.31 0-6 2.69-6 6s2.69 6 6 6c2.61 0 4.83-1.67 5.65-4H17v4h4v-4h2v-4H12.65zM7 14c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2z"/></svg>
        </div>
        <h1>Reset Password</h1>
        <p class="subtitle">Masukkan password baru Anda di halaman ini. Setelah berhasil, silakan langsung login lewat aplikasi.</p>
        <div class="card" id="resetFormCard">
          <div class="field">
            <label for="newPassword">Password Baru</label>
            <div class="input-wrap">
              <input id="newPassword" type="password" minlength="8" placeholder="Minimal 8 karakter" />
              <button type="button" class="toggle-visibility" aria-label="Tampilkan password" data-target="newPassword">
                <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 5c-5.05 0-9.27 3.11-11 7 1.73 3.89 5.95 7 11 7s9.27-3.11 11-7c-1.73-3.89-5.95-7-11-7zm0 11a4 4 0 1 1 0-8 4 4 0 0 1 0 8zm0-6.5A2.5 2.5 0 1 0 12 14a2.5 2.5 0 0 0 0-5z"/></svg>
              </button>
            </div>
            <div class="hint">Gunakan minimal 8 karakter.</div>
          </div>
          <div class="field">
            <label for="confirmPassword">Konfirmasi Password</label>
            <div class="input-wrap">
              <input id="confirmPassword" type="password" minlength="8" placeholder="Ulangi password baru" />
              <button type="button" class="toggle-visibility" aria-label="Tampilkan password" data-target="confirmPassword">
                <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 5c-5.05 0-9.27 3.11-11 7 1.73 3.89 5.95 7 11 7s9.27-3.11 11-7c-1.73-3.89-5.95-7-11-7zm0 11a4 4 0 1 1 0-8 4 4 0 0 1 0 8zm0-6.5A2.5 2.5 0 1 0 12 14a2.5 2.5 0 0 0 0-5z"/></svg>
              </button>
            </div>
          </div>
          <button id="submitResetBtn" class="btn-primary">Reset Password</button>
          <div id="fallbackError" class="danger"></div>
          <div id="fallbackSuccess" class="success"></div>
        </div>
        <div class="actions" id="successActions">
          <a href="laporfsm://login" class="btn-open-app">Buka Aplikasi</a>
        </div>
        <div class="footer">Lapor FSM - Fakultas Sains dan Matematika<br>Universitas Diponegoro</div>
    </div>
    <script>
      const btn = document.getElementById('submitResetBtn');
      const err = document.getElementById('fallbackError');
      const ok = document.getElementById('fallbackSuccess');
      const actions = document.getElementById('successActions');
      const formCard = document.getElementById('resetFormCard');
      const email = decodeURIComponent('${encodedEmail}');
      const token = decodeURIComponent('${encodedToken}');
      const eyeOpenIcon = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 5c-5.05 0-9.27 3.11-11 7 1.73 3.89 5.95 7 11 7s9.27-3.11 11-7c-1.73-3.89-5.95-7-11-7zm0 11a4 4 0 1 1 0-8 4 4 0 0 1 0 8zm0-6.5A2.5 2.5 0 1 0 12 14a2.5 2.5 0 0 0 0-5z"/></svg>';
      const eyeClosedIcon = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M2.7 3.7a1 1 0 0 1 1.4 0l16.2 16.2a1 1 0 1 1-1.4 1.4l-2.15-2.15A11.93 11.93 0 0 1 12 20c-5.05 0-9.27-3.11-11-7a12.66 12.66 0 0 1 4.12-4.85L2.7 5.12a1 1 0 0 1 0-1.42zm5.3 7.72A4 4 0 0 0 12.58 16l-1.56-1.56a2.5 2.5 0 0 1-3.02-3.02L8 11.42zm8.95 5.12-1.48-1.48A4 4 0 0 0 8.94 8.6L7.23 6.89A12.1 12.1 0 0 1 12 6c5.05 0 9.27 3.11 11 7a12.73 12.73 0 0 1-6.05 3.54z"/></svg>';

      document.querySelectorAll('.toggle-visibility').forEach((toggleBtn) => {
        toggleBtn.addEventListener('click', () => {
          const targetId = toggleBtn.getAttribute('data-target');
          const input = document.getElementById(targetId);
          const isPassword = input.type === 'password';
          input.type = isPassword ? 'text' : 'password';
          toggleBtn.setAttribute('aria-label', isPassword ? 'Sembunyikan password' : 'Tampilkan password');
          toggleBtn.innerHTML = isPassword ? eyeClosedIcon : eyeOpenIcon;
        });
      });

      btn.addEventListener('click', async () => {
        err.style.display = 'none';
        ok.style.display = 'none';
        const newPassword = document.getElementById('newPassword').value;
        const confirmPassword = document.getElementById('confirmPassword').value;

        if (!newPassword || newPassword.length < 8) {
          err.textContent = 'Password baru minimal 8 karakter.';
          err.style.display = 'block';
          return;
        }
        if (newPassword !== confirmPassword) {
          err.textContent = 'Konfirmasi password tidak sama.';
          err.style.display = 'block';
          return;
        }

        btn.disabled = true;
        btn.textContent = 'Memproses...';

        try {
          const response = await fetch(window.location.origin + window.location.pathname, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, token, newPassword }),
          });

          const payload = await response.json();
          if (!response.ok || payload.status !== 'success') {
            err.textContent = payload.message || 'Gagal mereset password.';
            err.style.display = 'block';
          } else {
            ok.textContent = 'Password berhasil direset. Silakan coba login di aplikasi.';
            ok.style.display = 'block';
            actions.style.display = 'flex';
            formCard.classList.add('success-state');
            btn.style.display = 'none';
            document.querySelectorAll('.field').forEach((field) => field.classList.add('hidden'));
          }
        } catch (e) {
          err.textContent = 'Terjadi gangguan koneksi saat reset password.';
          err.style.display = 'block';
        } finally {
          if (btn.style.display !== 'none') {
            btn.disabled = false;
            btn.textContent = 'Reset Password';
          }
        }
      });
    </script>
</body>
</html>`;
  }, {
    query: t.Object({
      token: t.String(),
      email: t.String(),
    })
  })

  // Reset Password - Verify token and update password
  .post('/reset-password', async ({ body, set }) => {
    const { email, token, newPassword } = body;

    console.log('[RESET PASSWORD] Attempting reset for email:', email);
    console.log('[RESET PASSWORD] Token received:', token);

    try {
      const user = await db.select().from(users).where(eq(users.email, email)).limit(1);
      const staffUser = user.length === 0
        ? await db.select().from(staff).where(eq(staff.email, email)).limit(1)
        : [];
      const isStaffAccount = staffUser.length > 0;

      if (user.length === 0 && staffUser.length === 0) {
        console.log('[RESET PASSWORD] User not found for email:', email);
        set.status = 400;
        return { status: 'error', message: 'Link reset password tidak valid.' };
      }

      const currentAccount = isStaffAccount ? staffUser[0] : user[0];
      const savedToken = currentAccount.passwordResetToken;
      const tokenExpiry = currentAccount.passwordResetExpiresAt;
      const actorRole = isStaffAccount ? staffUser[0].role : 'pelapor';
      const actorId = currentAccount.id.toString();
      const actorName = currentAccount.name;

      console.log('[RESET PASSWORD] Account found:', currentAccount.email);
      console.log('[RESET PASSWORD] Token in DB:', savedToken);
      console.log('[RESET PASSWORD] Token matches:', savedToken === token);

      if (savedToken !== token) {
        set.status = 400;
        return { status: 'error', message: 'Link reset password tidak valid atau sudah digunakan.' };
      }

      if (tokenExpiry && new Date() > new Date(tokenExpiry)) {
        console.log('[RESET PASSWORD] Token expired');
        set.status = 400;
        return { status: 'error', message: 'Link reset password sudah kedaluwarsa. Silakan minta link baru.' };
      }

      // Hash new password and update
      console.log('[RESET PASSWORD] Hashing new password...');
      const hashedPassword = await Bun.password.hash(newPassword);
      console.log('[RESET PASSWORD] Password hashed successfully');

      console.log('[RESET PASSWORD] Updating account password in database...');
      const updateResult = isStaffAccount
        ? await db.update(staff)
          .set({
            password: hashedPassword,
            passwordResetToken: null,
            passwordResetExpiresAt: null,
          })
          .where(eq(staff.id, currentAccount.id))
          .returning()
        : await db.update(users)
          .set({
            password: hashedPassword,
            passwordResetToken: null,
            passwordResetExpiresAt: null,
            isEmailVerified: true // Implicitly verify email on successful password reset
          })
          .where(eq(users.id, currentAccount.id))
          .returning();

      console.log('[RESET PASSWORD] Update result:', updateResult);

      if (updateResult.length === 0) {
        console.error('[RESET PASSWORD] Failed to update password - no rows affected');
        set.status = 500;
        return { status: 'error', message: 'Gagal mengupdate password di database' };
      }

      console.log('[RESET PASSWORD] Password updated successfully for account:', currentAccount.email);

      // Log password reset (non-blocking)
      try {
        await db.insert(reportLogs).values({
          action: 'password_reset',
          actorId,
          actorName,
          actorRole,
          reason: 'User mereset password melalui email',
        });
      } catch (logErr) {
        console.error('[RESET_PASSWORD] Log insertion failed (non-critical):', logErr);
      }

      return {
        status: 'success',
        message: 'Password berhasil direset. Silakan login dengan password baru Anda.'
      };
    } catch (error: any) {
      console.error('[RESET PASSWORD] Error:', error);
      set.status = 500;
      return { status: 'error', message: 'Terjadi kesalahan saat mereset password: ' + error.message };
    }
  }, {
    body: t.Object({
      email: t.String(),
      token: t.String(),
      newPassword: t.String()
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
      managedLocation: foundStaff[0].managedLocation ?? '',
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

  // Admin: Approve User (for external users - sends activation email)
  .post('/admin/approve-user', async ({ body, set }) => {
    const { userId } = body;

    const user = await db.select().from(users).where(eq(users.id, userId)).limit(1);

    if (user.length === 0) {
      set.status = 404;
      return { status: 'error', message: 'User tidak ditemukan' };
    }

    if (user[0].isVerified) {
      return { status: 'success', message: 'User sudah diverifikasi sebelumnya' };
    }

    // Generate activation token for external user
    const crypto = require('crypto');
    const activationToken = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    // Set isVerified = true and store activation token
    await db.update(users)
      .set({
        isVerified: true,
        emailVerificationToken: activationToken,
        emailVerificationExpiresAt: expiresAt
      })
      .where(eq(users.id, userId));

    // Log approval
    await db.insert(reportLogs).values({
      action: 'admin_approve_user',
      actorId: userId.toString(),
      actorName: user[0].name,
      actorRole: 'user',
      reason: 'Admin menyetujui user external',
    });

    // Send activation email to external user
    const apiUrl = process.env.API_URL || 'http://localhost:3000';
    const activationLink = `${apiUrl}/auth/activate?token=${activationToken}&email=${encodeURIComponent(user[0].email)}`;

    console.log(`[ADMIN] Activation token for ${user[0].email}: ${activationToken}`);
    try {
      EmailService.sendActivationEmail(user[0].email, user[0].name, activationLink, false);
    } catch (err) {
      console.error('[ADMIN] Failed to send activation email:', err);
    }

    return {
      status: 'success',
      message: 'User berhasil disetujui dan email aktivasi telah dikirim',
      data: {
        userId: userId,
        email: user[0].email,
        name: user[0].name
      }
    };
  }, {
    body: t.Object({
      userId: t.Number(),
    })
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
