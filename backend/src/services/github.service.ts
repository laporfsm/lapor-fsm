
export const GitHubService = {
    cachedRelease: null as any,
    lastFetch: 0,
    CACHE_TTL: 10 * 60 * 1000, // 10 minutes

    async getLatestRelease() {
        const now = Date.now();
        if (this.cachedRelease && (now - this.lastFetch < this.CACHE_TTL)) {
            return this.cachedRelease;
        }

        try {
            const headers: Record<string, string> = {
                'Accept': 'application/vnd.github.v3+json',
                'User-Agent': 'Lapor-FSM-Backend'
            };

            if (process.env.GITHUB_TOKEN) {
                headers['Authorization'] = `token ${process.env.GITHUB_TOKEN}`;
            }

            const response = await fetch('https://api.github.com/repos/laporfsm/lapor-fsm/releases/latest', {
                headers
            });

            if (!response.ok) {
                if (this.cachedRelease) return this.cachedRelease;
                throw new Error(`GitHub API returned ${response.status}`);
            }

            const data = (await response.json()) as any;
            const tag = data.tag_name || '0.0.0';
            
            // Extract version (v1.2.3 -> 1.2.3)
            const version = tag.startsWith('v') ? tag.substring(1) : tag;

            this.cachedRelease = {
                latestVersion: version,
                releaseNotes: data.body || '',
                publishedAt: data.published_at,
                // Direct to the releases page as requested
                url: 'https://github.com/laporfsm/lapor-fsm/releases'
            };
            this.lastFetch = now;
            return this.cachedRelease;
        } catch (error) {
            console.error('[GITHUB SERVICE] Failed to fetch latest release:', error);
            return this.cachedRelease;
        }
    }
};
