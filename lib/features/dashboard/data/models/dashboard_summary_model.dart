import '../../domain/entities/dashboard_summary_entity.dart';

class LowStockProductModel extends LowStockProductEntity {
  const LowStockProductModel({
    required super.productId,
    required super.productName,
    required super.quantityInStock,
    required super.reorderLevel,
  });

  factory LowStockProductModel.fromJson(Map<String, dynamic> json) {
    return LowStockProductModel(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantityInStock: json['quantity_in_stock'] as int,
      reorderLevel: json['reorder_level'] as int,
    );
  }
}

class BestSellingProductModel extends BestSellingProductEntity {
  const BestSellingProductModel({
    required super.productId,
    required super.productName,
    required super.quantitySold,
    required super.revenue,
  });

  factory BestSellingProductModel.fromJson(Map<String, dynamic> json) {
    return BestSellingProductModel(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantitySold: json['quantity_sold'] as int,
      revenue: double.parse(json['revenue'].toString()),
    );
  }
}

class DashboardSummaryModel extends DashboardSummaryEntity {
  const DashboardSummaryModel({
    required super.todaySalesTotal,
    required super.todaySalesCount,
    required super.todayGstCollected,
    required super.monthRevenueTotal,
    required super.monthSalesCount,
    required super.lowStockCount,
    required super.lowStockProducts,
    required super.bestSellingProducts,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      todaySalesTotal: double.parse(json['today_sales_total'].toString()),
      todaySalesCount: json['today_sales_count'] as int,
      todayGstCollected: double.parse(json['today_gst_collected'].toString()),
      monthRevenueTotal: double.parse(json['month_revenue_total'].toString()),
      monthSalesCount: json['month_sales_count'] as int,
      lowStockCount: json['low_stock_count'] as int,
      lowStockProducts: (json['low_stock_products'] as List)
          .map((e) => LowStockProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      bestSellingProducts: (json['best_selling_products'] as List)
          .map((e) => BestSellingProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RevenuePointModel extends RevenuePointEntity {
  const RevenuePointModel({required super.day, required super.revenue, required super.invoiceCount});

  factory RevenuePointModel.fromJson(Map<String, dynamic> json) {
    return RevenuePointModel(
      day: DateTime.parse(json['day'] as String),
      revenue: double.parse(json['revenue'].toString()),
      invoiceCount: json['invoice_count'] as int,
    );
  }
}
