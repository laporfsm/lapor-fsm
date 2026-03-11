
/**
 * Utility to check for mandatory environment variables on startup.
 * Provides clear warnings if critical services (Email, S3, FCM) will be disabled.
 */
export const checkEnv = () => {
    const mandatory = ['DATABASE_URL', 'JWT_SECRET', 'API_URL'];
    const services = {
        Email: ['SMTP_HOST', 'SMTP_PORT', 'SMTP_USER', 'SMTP_PASS'],
        Storage: ['S3_ENDPOINT', 'S3_ACCESS_KEY', 'S3_SECRET_KEY', 'S3_BUCKET'],
        Firebase: ['FIREBASE_SERVICE_ACCOUNT'],
    };

    console.log('--- 🛡️  Environment Check ---');

    // Check mandatory
    const missingMandatory = mandatory.filter((key) => !process.env[key]);
    if (missingMandatory.length > 0) {
        console.error(`❌ CRITICAL: Missing mandatory env vars: ${missingMandatory.join(', ')}`);
    } else {
        console.log('✅ Mandatory environment variables present.');
    }

    // Check optional services
    Object.entries(services).forEach(([name, keys]) => {
        const missing = keys.filter((key) => !process.env[key]);
        if (missing.length > 0) {
            console.warn(`⚠️  ${name} Service may be disabled. Missing: ${missing.join(', ')}`);
        } else {
            console.log(`✅ ${name} Service configuration present.`);
        }
    });

    console.log('----------------------------\n');
};
