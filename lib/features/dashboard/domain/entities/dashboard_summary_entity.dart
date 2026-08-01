import 'package:equatable/equatable.dart';

class LowStockProductEntity extends Equatable {
  const LowStockProductEntity({
    required this.productId,
    required this.productName,
    required this.quantityInStock,
    required this.reorderLevel,
  });

  final String productId;
  final String productName;
  final int quantityInStock;
  final int reorderLevel;

  @override
  List<Object?> get props => [productId, quantityInStock];
}

class BestSellingProductEntity extends Equatable {
  const BestSellingProductEntity({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });

  final String productId;
  final String productName;
  final int quantitySold;
  final double revenue;

  @override
  List<Object?> get props => [productId, quantitySold];
}

class DashboardSummaryEntity extends Equatable {
  const DashboardSummaryEntity({
    required this.todaySalesTotal,
    required this.todaySalesCount,
    required this.todayGstCollected,
    required this.monthRevenueTotal,
    required this.monthSalesCount,
    required this.lowStockCount,
    required this.lowStockProducts,
    required this.bestSellingProducts,
  });

  final double todaySalesTotal;
  final int todaySalesCount;
  final double todayGstCollected;
  final double monthRevenueTotal;
  final int monthSalesCount;
  final int lowStockCount;
  final List<LowStockProductEntity> lowStockProducts;
  final List<BestSellingProductEntity> bestSellingProducts;

  @override
  List<Object?> get props => [todaySalesTotal, monthRevenueTotal, lowStockCount];
}

class RevenuePointEntity extends Equatable {
  const RevenuePointEntity({required this.day, required this.revenue, required this.invoiceCount});
  final DateTime day;
  final double revenue;
  final int invoiceCount;

  @override
  List<Object?> get props => [day, revenue];
}
