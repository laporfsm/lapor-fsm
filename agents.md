# Agents Operational Notes

1. Android release builds must always use the official release keystore/signature.
   - Do not allow fallback to debug signing for release artifacts.
   - If signing config is incomplete, release build must fail.

2. After a GitHub release is uploaded successfully, remove local release artifacts.
   - Delete local `releases/` contents to avoid stale APK reuse and workspace clutter.

3. If users see `App not installed as package conflicts with an existing package`,
   - instruct a one-time uninstall of the old app,
   - then install the latest APK signed with the official release key.
