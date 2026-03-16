import { Elysia } from 'elysia';

const normalizeUrl = (value?: string) => {
    if (!value) return null;
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : null;
};

export const appController = new Elysia({ prefix: '/app' })
    .get('/version', () => {
        const latestVersion = process.env.APP_LATEST_VERSION ?? '0.0.0';
        const minVersion = process.env.APP_MIN_VERSION ?? '0.0.0';

        return {
            status: 'success',
            data: {
                latestVersion,
                minVersion,
                androidUrl: normalizeUrl(process.env.APP_ANDROID_URL),
                iosUrl: normalizeUrl(process.env.APP_IOS_URL),
                webUrl: normalizeUrl(process.env.APP_WEB_URL),
                message: normalizeUrl(process.env.APP_UPDATE_MESSAGE),
                releaseNotes: normalizeUrl(process.env.APP_RELEASE_NOTES),
                updatedAt: new Date().toISOString(),
            },
        };
    });
