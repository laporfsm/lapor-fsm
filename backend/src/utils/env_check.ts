/**
 * Utility to check for mandatory environment variables on startup.
 * Provides clear warnings if critical services (Email, Supabase, FCM) will be disabled.
 */
export const checkEnv = () => {
    const mandatory = ['DATABASE_URL', 'JWT_SECRET', 'API_URL'];
    const services = {
        Email: ['SMTP_HOST', 'SMTP_PORT', 'SMTP_USER', 'SMTP_PASS'],
        Supabase: ['SUPABASE_URL', 'SUPABASE_ANON_KEY'],
        Firebase: ['FIREBASE_SERVICE_ACCOUNT'],
    };

    console.log('--- Environment Check ---');

    const missingMandatory = mandatory.filter((key) => !process.env[key]);
    if (missingMandatory.length > 0) {
        console.error(`CRITICAL: Missing mandatory env vars: ${missingMandatory.join(', ')}`);
    } else {
        console.log('OK: Mandatory environment variables present.');
    }

    Object.entries(services).forEach(([name, keys]) => {
        const missing = keys.filter((key) => !process.env[key]);
        if (missing.length > 0) {
            console.warn(`WARN: ${name} service may be disabled. Missing: ${missing.join(', ')}`);
        } else {
            console.log(`OK: ${name} service configuration present.`);
        }
    });

    console.log('-------------------------\n');
};