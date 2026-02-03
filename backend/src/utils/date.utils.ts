/**
 * Get the start of the current week (Monday at 00:00:00)
 */
export function getStartOfWeek(): Date {
    const now = new Date();
    const day = now.getDay(); // 0 (Sun) to 6 (Sat)

    // Calculate difference to get to previous Monday
    // If today is Sunday (0), diff is 6 days back
    // If today is Monday (1), diff is 0 days back
    // Formula: (day + 6) % 7 gives accurate days to subtract for Monday-start week
    const diff = now.getDate() - day + (day === 0 ? -6 : 1);

    const startOfWeek = new Date(now.setDate(diff));
    startOfWeek.setHours(0, 0, 0, 0);

    return startOfWeek;
}

/**
 * Get the start of the current month (1st at 00:00:00)
 */
export function getStartOfMonth(): Date {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), 1);
}

/**
 * Get the start of the current day (00:00:00)
 */
export function getStartOfDay(): Date {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}
