import { Elysia } from 'elysia';
import { GitHubService } from '../services/github.service';

const normalizeUrl = (value?: string) => {
    if (!value) return null;
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : null;
};

export const appController = new Elysia({ prefix: '/app' })
    .get('/version', async () => {
        const github = await GitHubService.getLatestRelease();
        
        // Environment Overrides (prioritize Env if set specifically, else use GitHub)
        const latestVersion = process.env.APP_LATEST_VERSION || github?.latestVersion || '0.0.0';
        const minVersion = process.env.APP_MIN_VERSION ?? '0.0.0';
        
        // GitHub release URL or Env URL
        const downloadUrl = normalizeUrl(process.env.APP_ANDROID_URL) || github?.url || 'https://github.com/laporfsm/lapor-fsm/releases';

        return {
            status: 'success',
            data: {
                latestVersion,
                minVersion,
                androidUrl: downloadUrl,
                iosUrl: normalizeUrl(process.env.APP_IOS_URL) || downloadUrl,
                webUrl: normalizeUrl(process.env.APP_WEB_URL) || downloadUrl,
                message: normalizeUrl(process.env.APP_UPDATE_MESSAGE) || `Versi terbaru ${latestVersion} telah tersedia di GitHub.`,
                releaseNotes: normalizeUrl(process.env.APP_RELEASE_NOTES) || github?.releaseNotes,
                updatedAt: github?.publishedAt || new Date().toISOString(),
            },
        };
    });
