class DashboardMetrics {
  final double todaySalesTotal;
  final int todayInvoicesCount;
  final int lowStockProductsCount;
  final int pendingChecksCount;
  final double pendingChecksTotal;
  final int activeDispatchesCount;
  final double totalCustomerDebt;
  final double averageFleetCostPerKm;

  const DashboardMetrics({
    required this.todaySalesTotal,
    required this.todayInvoicesCount,
    required this.lowStockProductsCount,
    required this.pendingChecksCount,
    required this.pendingChecksTotal,
    required this.activeDispatchesCount,
    required this.totalCustomerDebt,
    required this.averageFleetCostPerKm,
  });

  factory DashboardMetrics.empty() {
    return const DashboardMetrics(
      todaySalesTotal: 0.0,
      todayInvoicesCount: 0,
      lowStockProductsCount: 0,
      pendingChecksCount: 0,
      pendingChecksTotal: 0.0,
      activeDispatchesCount: 0,
      totalCustomerDebt: 0.0,
      averageFleetCostPerKm: 0.0,
    );
  }
}
