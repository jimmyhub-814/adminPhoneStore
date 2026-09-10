class Statistics {
  static const idField = 'id';
  static const completedOrderField = 'completedOrder';
  static const cancelledOrderField = 'cancelledOrder';
  String id;
  Info completedOrder;
  Info cancelledOrder;

  Statistics({
    required this.id,
    required this.cancelledOrder,
    required this.completedOrder,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      idField: id,
      cancelledOrderField: cancelledOrder,
      completedOrderField: completedOrder,
    };
  }

  factory Statistics.fromMap(Map<String, dynamic> map, String documentId) {
    return Statistics(
      id: (map[idField] is String && map[idField] != null && map[idField] != "")
          ? map[idField]
          : documentId,
      cancelledOrder: map[cancelledOrderField] is Map
          ? Info.fromMap(Map<String, dynamic>.from(map[cancelledOrderField]))
          : Info(revenue: 0, orderCount: 0, productCount: 0),
      completedOrder: map[completedOrderField] is Map
          ? Info.fromMap(Map<String, dynamic>.from(map[completedOrderField]))
          : Info(revenue: 0, orderCount: 0, productCount: 0),
    );
  }
}

class Info {
  static const revenueField = 'revenue';
  static const orderCountField = 'orderCount';
  static const productCountField = 'productCount';
  double revenue;
  int orderCount;
  int productCount;
  Info({
    required this.revenue,
    required this.orderCount,
    required this.productCount,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      revenueField: revenue,
      orderCountField: orderCount,
      productCountField: productCount,
    };
  }

  factory Info.fromMap(Map<String, dynamic> map) {
    return Info(
      revenue: (map[revenueField] is num) ? (map[revenueField] as num).toDouble() : 0,
      orderCount:
          (map[orderCountField] is num) ? (map[orderCountField] as num).toInt() : 0,
      productCount: (map[productCountField] is num)
          ? (map[productCountField] as num).toInt()
          : 0,
    );
  }
}
