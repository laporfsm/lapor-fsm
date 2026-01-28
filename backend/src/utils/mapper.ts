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
