import nodemailer from 'nodemailer';

async function testConnection() {
    console.log('Testing SMTP connection...');
    console.log('User:', process.env.SMTP_USER);

    const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST || 'smtp.gmail.com',
        port: parseInt(process.env.SMTP_PORT || '465'),
        secure: process.env.SMTP_PORT === '465',
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS
        }
    });

    try {
        await transporter.verify();
        console.log('✅ Connection success! SMTP is configured correctly.');
    } catch (error) {
        console.error('❌ Connection failed:', error);
    }
}

testConnection();
