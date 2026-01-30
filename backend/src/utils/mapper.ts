export const mapToMobileReport = (report: any, logs: any[] = []) => {
  if (!report) return null;

  return {
    ...report,
    id: report.id.toString(),
    reporterId: report.userId?.toString() || report.staffId?.toString() || "",
    reporterName: report.reporterName || "Unknown",
    reporterEmail: report.reporterEmail || "",
    reporterPhone: report.reporterPhone || "",
    category: report.categoryName || "Unknown",
    status: report.status, // Matches ReportStatus enum in mobile
    createdAt: report.createdAt instanceof Date ? report.createdAt.toISOString() : new Date().toISOString(),
    imageUrl: report.mediaUrls && report.mediaUrls.length > 0 ? report.mediaUrls[0] : null,
    mediaUrls: report.mediaUrls || [],
    handledBy: report.handlerName ? [report.handlerName] : [],
    supervisorId: report.approvedBy?.toString() || report.verifiedBy?.toString() || "",
    supervisorName: report.supervisorName || "",
    logs: (logs || []).map(log => ({
      ...log,
      id: log.id.toString(),
      timestamp: log.timestamp instanceof Date ? log.timestamp.toISOString() : new Date().toISOString(),
      fromStatus: log.fromStatus || "pending",
      toStatus: log.toStatus || "pending",
    }))
  };
};

export const mapToMobileUser = (user: any) => {
  if (!user) return null;
  return {
    ...user,
    id: user.id.toString(),
    password: '', // Safety check
    createdAt: user.createdAt instanceof Date ? user.createdAt.toISOString() : user.createdAt,
    updatedAt: user.updatedAt instanceof Date ? user.updatedAt.toISOString() : user.updatedAt,
  };
};

export const mapToMobileNotification = (notif: any) => {
  if (!notif) return null;
  return {
    ...notif,
    id: notif.id.toString(),
    userId: notif.userId?.toString(),
    staffId: notif.staffId?.toString(),
    reportId: notif.reportId?.toString(),
    createdAt: notif.createdAt instanceof Date ? notif.createdAt.toISOString() : notif.createdAt,
  };
};
