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
        return lowerEmail.endsWith('@undip.ac.id') ||
          lowerEmail.endsWith('@students.undip.ac.id') ||
          lowerEmail.endsWith('@live.undip.ac.id') ||
          lowerEmail.endsWith('@lecturer.undip.ac.id') ||
          lowerEmail.endsWith('@staff.undip.ac.id');
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
        isVerified: false, // Not verified until activation
        isEmailVerified: false,
        emailVerificationToken: activationToken,
        emailVerificationExpiresAt: expiresAt,
      }).returning();

      // Log registration
      await db.insert(reportLogs).values({
        action: 'register',
        actorId: newUser[0].id.toString(),
        actorName: newUser[0].name,
        actorRole: 'user',
        reason: isUndip
          ? 'User mendaftar (UNDIP Email - Menunggu Aktivasi)'
          : 'User mendaftar (Non-UNDIP, Menunggu Approval Admin)',
      });

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
      set.status = 500;
      return { status: 'error', message: 'Internal Server Error' }; // Don't leak technical messages
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
    console.log(`[ACTIVATE] Token received: ${token?.substring(0, 20)}...`);
    
    const user = await db.select().from(users).where(eq(users.email, email)).limit(1);

    if (user.length === 0) {
      console.log(`[ACTIVATE] User not found: ${email}`);
      set.status = 404;
      return { status: 'error', message: 'User tidak ditemukan' };
    }

    console.log(`[ACTIVATE] User found: ${user[0].id}, isEmailVerified: ${user[0].isEmailVerified}`);
    console.log(`[ACTIVATE] Stored token: ${user[0].emailVerificationToken?.substring(0, 20)}...`);

    if (user[0].isEmailVerified) {
      console.log(`[ACTIVATE] User already activated`);
      return { status: 'success', message: 'Akun Anda sudah aktif. Silakan login.' };
    }

    if (user[0].emailVerificationToken !== token) {
      console.log(`[ACTIVATE] Token mismatch!`);
      set.status = 400;
      return { status: 'error', message: 'Token aktivasi tidak valid' };
    }

    if (user[0].emailVerificationExpiresAt && new Date() > new Date(user[0].emailVerificationExpiresAt)) {
      console.log(`[ACTIVATE] Token expired`);
      set.status = 400;
      return { status: 'error', message: 'Token aktivasi telah kedaluwarsa. Silakan minta yang baru.' };
    }

    // For both UNDIP and External (after admin approval): activate immediately when clicking link
    // Mark email as verified and clear token
    await db.update(users)
      .set({
        isEmailVerified: true,
        emailVerificationToken: null,
        emailVerificationExpiresAt: null
      })
      .where(eq(users.id, user[0].id));

    console.log(`[ACTIVATE] User ${user[0].id} activated successfully`);

    // Log activation
    await db.insert(reportLogs).values({
      action: 'activate_account',
      actorId: user[0].id.toString(),
      actorName: user[0].name,
      actorRole: 'user',
      reason: isUndip ? 'User UNDIP mengaktifkan akun' : 'User External verifikasi email',
    });

    // Notify admin for non-UNDIP
    if (!isUndip) {
      await NotificationService.notifyRole('admin', 'User Siap Diverifikasi', `User ${user[0].name} (${user[0].email}) telah verifikasi email dan menunggu persetujuan admin.`);
    }

    const frontendUrl = process.env.APP_URL || 'http://localhost:8080';
    const loginUrl = `${frontendUrl}/#/login`;
    
    // Return HTML page instead of JSON for better UX
    const htmlResponse = `
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aktivasi Akun - Lapor FSM</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            max-width: 500px;
            width: 100%;
            text-align: center;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        .icon {
            width: 80px;
            height: 80px;
            background: #10b981;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 24px;
        }
        .icon svg {
            width: 40px;
            height: 40px;
            fill: white;
        }
        h1 {
            color: #1f2937;
            font-size: 24px;
            margin-bottom: 16px;
            font-weight: 700;
        }
        p {
            color: #6b7280;
            font-size: 16px;
            line-height: 1.6;
            margin-bottom: 24px;
        }
        .btn {
            display: inline-block;
            background: #3b82f6;
            color: white;
            text-decoration: none;
            padding: 14px 32px;
            border-radius: 10px;
            font-weight: 600;
            font-size: 16px;
            transition: all 0.3s;
        }
        .btn:hover {
            background: #2563eb;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
        }
        .footer {
            margin-top: 32px;
            padding-top: 24px;
            border-top: 1px solid #e5e7eb;
            color: #9ca3af;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">
            <svg viewBox="0 0 24 24"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>
        </div>
        <h1>Akun Anda Telah Aktif!</h1>
        <p>
            Selamat! Akun Lapor FSM Anda telah berhasil diaktivasi. Anda sekarang dapat login dan mulai menggunakan aplikasi.
        </p>
        <a href="${loginUrl}" class="btn">Login Sekarang</a>
        <div class="footer">
            Lapor FSM - Fakultas Sains dan Matematika<br>Universitas Diponegoro
        </div>
    </div>
</body>
</html>`;
    
    set.headers['Content-Type'] = 'text/html';
    return htmlResponse;
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

    // Check in users table first
    let user = await db.select().from(users).where(eq(users.email, email)).limit(1);
    console.log('[FORGOT PASSWORD] User found in users table:', user.length > 0);

    let isStaff = false;

    // If not found in users, check in staff table
    if (user.length === 0) {
      const staffUser = await db.select().from(staff).where(eq(staff.email, email)).limit(1);
      if (staffUser.length === 0) {
        // PERUBAHAN: Memberitahu user jika email tidak ditemukan untuk UX yang lebih baik
        console.log('[FORGOT PASSWORD] User NOT found (returning 404):', email);
        set.status = 404;
        return {
          status: 'error',
          message: 'Email tidak terdaftar dalam sistem.'
        };
      }
      isStaff = true;
      // For staff, we'll use a different approach since staff table doesn't have reset token fields
      // For now, let's keep it simple or implement staff specific logic later
      // But for this request, we proceed assuming user table logic primarily or adapt
      // NOTE: Current implementation assumes user table structure for token updates.
      // If staff needs reset, they should contact admin or we need to add fields to staff table.
      set.status = 400;
      return { status: 'error', message: 'Fitur reset password untuk staff belum tersedia. Hubungi admin.' };
    }

    // Generate reset token
    const crypto = require('crypto');
    const resetToken = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 1); // 1 hour expiry

    if (!isStaff && user.length > 0) {
      // Update user with reset token
      await db.update(users)
        .set({
          passwordResetToken: resetToken,
          passwordResetExpiresAt: expiresAt
        })
        .where(eq(users.id, user[0].id));

      // Construct reset link (using app URL from env or default)
      const appUrl = process.env.APP_URL || 'http://localhost:8080';
      const resetLink = `${appUrl}/#/reset-password?token=${resetToken}&email=${encodeURIComponent(email)}`;

      // Send email
      try {
        await EmailService.sendPasswordResetEmail(email, user[0].name, resetLink);
      } catch (err) {
        console.error('[AUTH] Failed to send password reset email:', err);
      }

      console.log(`[AUTH] Password reset token for ${email}: ${resetToken}`);
    }

    return {
      status: 'success',
      message: 'Jika email terdaftar, link reset password akan dikirim.'
    };
  }, {
    body: t.Object({
      email: t.String()
    })
  })

  // Reset Password - Verify token and update password
  .post('/reset-password', async ({ body, set }) => {
    const { email, token, newPassword } = body;

    console.log('[RESET PASSWORD] Attempting reset for email:', email);
    console.log('[RESET PASSWORD] Token received:', token);

    try {
      // Find user with valid reset token
      const user = await db.select().from(users).where(eq(users.email, email)).limit(1);

      if (user.length === 0) {
        console.log('[RESET PASSWORD] User not found for email:', email);
        set.status = 400;
        return { status: 'error', message: 'Link reset password tidak valid.' };
      }

      console.log('[RESET PASSWORD] User found:', user[0].email);
      console.log('[RESET PASSWORD] Token in DB:', user[0].passwordResetToken);
      console.log('[RESET PASSWORD] Token matches:', user[0].passwordResetToken === token);

      if (user[0].passwordResetToken !== token) {
        set.status = 400;
        return { status: 'error', message: 'Link reset password tidak valid atau sudah digunakan.' };
      }

      if (user[0].passwordResetExpiresAt && new Date() > new Date(user[0].passwordResetExpiresAt)) {
        console.log('[RESET PASSWORD] Token expired');
        set.status = 400;
        return { status: 'error', message: 'Link reset password sudah kedaluwarsa. Silakan minta link baru.' };
      }

      // Hash new password and update
      console.log('[RESET PASSWORD] Hashing new password...');
      const hashedPassword = await Bun.password.hash(newPassword);
      console.log('[RESET PASSWORD] Password hashed successfully');

      console.log('[RESET PASSWORD] Updating user password in database...');
      const updateResult = await db.update(users)
        .set({
          password: hashedPassword,
          passwordResetToken: null,
          passwordResetExpiresAt: null,
          isEmailVerified: true // Implicitly verify email on successful password reset
        })
        .where(eq(users.id, user[0].id))
        .returning();

      console.log('[RESET PASSWORD] Update result:', updateResult);

      if (updateResult.length === 0) {
        console.error('[RESET PASSWORD] Failed to update password - no rows affected');
        set.status = 500;
        return { status: 'error', message: 'Gagal mengupdate password di database' };
      }

      console.log('[RESET PASSWORD] Password updated successfully for user:', user[0].email);

      // Log password reset
      await db.insert(reportLogs).values({
        action: 'password_reset',
        actorId: user[0].id.toString(),
        actorName: user[0].name,
        actorRole: 'user',
        reason: 'User mereset password melalui email',
      });

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
