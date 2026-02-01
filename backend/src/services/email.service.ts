import nodemailer from 'nodemailer';

export class EmailService {
    private static transporter = nodemailer.createTransport({
        service: 'gmail', // Use 'gmail' for simplicity, or configure host/port manually
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
}
