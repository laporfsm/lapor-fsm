import nodemailer from 'nodemailer';

export class EmailService {
    private static transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST || 'smtp.gmail.com',
        port: parseInt(process.env.SMTP_PORT || '465'),
        secure: process.env.SMTP_PORT === '465', // true for 465, false for other ports
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS
        }
    });

    /**
     * Send a verification email to the user
     * @param to User's email address
     * @param name User's name
     * @param token Verification token (6 digits)
     */
    static async sendVerificationEmail(to: string, name: string, token: string) {
        try {
            const info = await this.transporter.sendMail({
                from: `"Lapor FSM" <${process.env.SMTP_USER}>`,
                to: to,
                subject: 'Verifikasi Akun Lapor FSM Anda',
                html: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                        <h2 style="color: #0d47a1;">Verifikasi Email Anda</h2>
                        <p>Halo <strong>${name}</strong>,</p>
                        <p>Terima kasih telah mendaftar di aplikasi <strong>Lapor FSM</strong>.</p>
                        <p>Gunakan kode verifikasi berikut untuk mengaktifkan akun Anda:</p>
                        <div style="background-color: #f5f5f5; padding: 15px; text-align: center; border-radius: 5px; font-size: 24px; letter-spacing: 5px; font-weight: bold; color: #333;">
                            ${token}
                        </div>
                        <p style="margin-top: 20px;">Kode ini akan kedaluwarsa dalam 15 menit.</p>
                        <p>Jika Anda tidak merasa mendaftar, abaikan email ini.</p>
                        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                        <p style="font-size: 12px; color: #888;">Lapor FSM - Fakultas Sains dan Matematika Universitas Diponegoro</p>
                    </div>
                `
            });
            console.log(`[EMAIL] Verification sent to ${to}: ${info.messageId}`);
            return true;
        } catch (error) {
            console.error('[EMAIL] Failed to send verification email:', error);
            // Don't throw error to User, just log it. 
            // In strict scenarios, we might want to tell the user service is unavailable.
            return false;
        }
    }

    /**
     * Send an account activation email to the user
     * @param to User's email address
     * @param name User's name
     * @param activationLink Activation link
     * @param isUndip Whether user has UNDIP email
     */
    static async sendActivationEmail(to: string, name: string, activationLink: string, isUndip: boolean) {
        try {
            const info = await this.transporter.sendMail({
                from: `"Lapor FSM" <${process.env.SMTP_USER}>`,
                to: to,
                subject: 'Aktivasi Akun Lapor FSM Anda',
                html: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                        <h2 style="color: #0d47a1;">Aktivasi Akun Anda</h2>
                        <p>Halo <strong>${name}</strong>,</p>
                        <p>Terima kasih telah mendaftar di aplikasi <strong>Lapor FSM</strong>.</p>
                        <p>Klik tombol di bawah ini untuk mengaktifkan akun Anda:</p>
                        <div style="text-align: center; margin: 30px 0;">
                            <a href="${activationLink}" style="background-color: #0d47a1; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; font-weight: bold; display: inline-block;">
                                Aktifkan Akun
                            </a>
                        </div>
                        <p style="margin-top: 20px;"><strong>Link ini akan kedaluwarsa dalam 24 jam.</strong></p>
                        ${!isUndip ? '<p style="color: #2e7d32;"><strong>Selamat!</strong> Akun Anda telah disetujui oleh admin. Silakan klik tombol di atas untuk mengaktifkan akun dan mulai menggunakan aplikasi.</p>' : ''}
                        <p>Jika Anda tidak merasa mendaftar, abaikan email ini.</p>
                        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                        <p style="font-size: 12px; color: #888;">Lapor FSM - Fakultas Sains dan Matematika Universitas Diponegoro</p>
                    </div>
                `
            });
            console.log(`[EMAIL] Activation email sent to ${to}: ${info.messageId}`);
            return true;
        } catch (error) {
            console.error('[EMAIL] Failed to send activation email:', error);
            return false;
        }
    }

    /**
     * Send approval notification email after admin approves external user
     * @param to User's email address
     * @param name User's name
     */
    static async sendApprovalNotificationEmail(to: string, name: string) {
        try {
            const info = await this.transporter.sendMail({
                from: `"Lapor FSM" <${process.env.SMTP_USER}>`,
                to: to,
                subject: 'Akun Lapor FSM Anda Telah Disetujui',
                html: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                        <h2 style="color: #0d47a1;">Selamat! Akun Anda Aktif</h2>
                        <p>Halo <strong>${name}</strong>,</p>
                        <p>Akun Anda di aplikasi <strong>Lapor FSM</strong> telah <strong>disetujui oleh admin</strong>.</p>
                        <p>Anda sekarang dapat login dan mulai menggunakan aplikasi.</p>
                        <div style="text-align: center; margin: 30px 0;">
                            <a href="${process.env.APP_URL || 'http://localhost:8080'}/#/login" style="background-color: #0d47a1; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; font-weight: bold; display: inline-block;">
                                Login Sekarang
                            </a>
                        </div>
                        <p>Terima kasih telah bergabung dengan Lapor FSM!</p>
                        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                        <p style="font-size: 12px; color: #888;">Lapor FSM - Fakultas Sains dan Matematika Universitas Diponegoro</p>
                    </div>
                `
            });
            console.log(`[EMAIL] Approval notification sent to ${to}: ${info.messageId}`);
            return true;
        } catch (error) {
            console.error('[EMAIL] Failed to send approval notification:', error);
            return false;
        }
    }

    /**
     * Send a password reset email to the user
     * @param to User's email address
     * @param name User's name
     * @param resetLink Password reset link
     */
    static async sendPasswordResetEmail(to: string, name: string, resetLink: string) {
        try {
            const info = await this.transporter.sendMail({
                from: `"Lapor FSM" <${process.env.SMTP_USER}>`,
                to: to,
                subject: 'Reset Password Akun Lapor FSM',
                html: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                        <h2 style="color: #0d47a1;">Reset Password Anda</h2>
                        <p>Halo <strong>${name}</strong>,</p>
                        <p>Kami menerima permintaan untuk mereset password akun <strong>Lapor FSM</strong> Anda.</p>
                        <p>Klik tombol di bawah ini untuk mereset password Anda:</p>
                        <div style="text-align: center; margin: 30px 0;">
                            <a href="${resetLink}" style="background-color: #0d47a1; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; font-weight: bold; display: inline-block;">
                                Reset Password
                            </a>
                        </div>
                        <p style="margin-top: 20px;"><strong>Link ini akan kedaluwarsa dalam 1 jam.</strong></p>
                        <p>Jika Anda tidak meminta reset password, abaikan email ini. Password Anda akan tetap aman.</p>
                        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                        <p style="font-size: 12px; color: #888;">Lapor FSM - Fakultas Sains dan Matematika Universitas Diponegoro</p>
                    </div>
                `
            });
            console.log(`[EMAIL] Password reset email sent to ${to}: ${info.messageId}`);
            return true;
        } catch (error) {
            console.error('[EMAIL] Failed to send password reset email:', error);
            return false;
        }
    }
}
