import 'package:admin/app_constants/providers.dart';
import 'package:admin/models/statistics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StatisticsProvider extends ChangeNotifier {
  Statistics? _statisticsYear;
  Statistics? get statisticsYear => _statisticsYear;

  Future<void> updateStatistics(
      double revenue, int orderCount, int productCount, String status) async {
    String year = DateTime.now().year.toString();
    String month =
        '${DateTime.now().year}_${DateTime.now().month.toString().padLeft(2, '0')}';
    String day =
        '${DateTime.now().year}_${DateTime.now().month.toString().padLeft(2, '0')}_${DateTime.now().day.toString().padLeft(2, '0')}';
    final statisticsYearRef = Collections.statistics.doc(year);

    final statisticsMonthRef = Collections.statisticsMonth(year).doc(month);

    final statisticsDayRef = Collections.statisticsDay(year, month).doc(day);

    final field = status == Statistics.completedOrderField
        ? Statistics.completedOrderField
        : Statistics.cancelledOrderField;
    if (status == Statistics.completedOrderField) {
      await statisticsYearRef.set({
        Statistics.idField: year,
        field: {
          Info.revenueField: FieldValue.increment(revenue),
          Info.orderCountField: FieldValue.increment(orderCount),
          Info.productCountField: FieldValue.increment(productCount),
        }
      }, SetOptions(merge: true));
    } else {
      await statisticsYearRef.set({
        Statistics.idField: year,
        field: {
          Info.revenueField: FieldValue.increment(revenue),
          Info.orderCountField: FieldValue.increment(orderCount),
          Info.productCountField: FieldValue.increment(productCount),
        }
      }, SetOptions(merge: true));
    }

    await statisticsMonthRef.set({
      Statistics.idField: month,
      field: {
        Info.revenueField: FieldValue.increment(revenue),
        Info.orderCountField: FieldValue.increment(orderCount),
        Info.productCountField: FieldValue.increment(productCount),
      }
    }, SetOptions(merge: true));

    await statisticsDayRef.set({
      Statistics.idField: day,
      field: {
        Info.revenueField: FieldValue.increment(revenue),
        Info.orderCountField: FieldValue.increment(orderCount),
        Info.productCountField: FieldValue.increment(productCount),
      }
    }, SetOptions(merge: true));
  }

  Future<Statistics?> getStatisticsYear() async {
    final year = DateTime.now().year.toString();

    final doc = await Collections.statistics
        .doc(year)
        .get();

    final data = doc.data();
    if (data == null) return null;

    return Statistics.fromMap(data, data[Statistics.idField]);
  }

  Future<List<Statistics>> getStatisticsMonth() async {
    final year = DateTime.now().year.toString();

    List<Statistics> statistics = [];

    final snapshot = await Collections.statisticsMonth(year)
        .get();

    for (var doc in snapshot.docs) {
      try {
        print("DOC ${doc.id}: ${doc.data()}"); 
        final item = Statistics.fromMap(doc.data(), doc.id);
        statistics.add(item);
      } catch (e) {
        print("❌ Lỗi parse Document ${doc.id}: $e");
        continue;
      }
    }
    return statistics;
  }

  Future<Map<String, dynamic>> getAllStatistics() async {
    final results = await Future.wait([
      getStatisticsYear(),
      getStatisticsMonth(),
    ]);

    return {
      "year": results[0] as Statistics?,
      "month": results[1] as List<Statistics>,
    };
  }

  Future<List<Statistics>> getStatisticsDay() async {
    final year = DateTime.now().year.toString();
    String month =
        '${DateTime.now().year}_${DateTime.now().month.toString().padLeft(2, '0')}';

    List<Statistics> statistics = [];

    final snapshot = await Collections.statisticsDay(year, month).get();

    for (var doc in snapshot.docs) {
      try {
        print("DOC ${doc.id}: ${doc.data()}");
        
        final item = Statistics.fromMap(doc.data(), doc.id);
        statistics.add(item);
      } catch (e) {
        print("❌ Lỗi ${doc.id}: $e");
        continue;
      }
    }
    return statistics;
  }
  
  Future<List<Statistics>> getStatisticsDayOfMonth(String month) async {
    final year = DateTime.now().year.toString(); 
    List<Statistics> statistics = [];

    final snapshot = await Collections.statisticsDay(year, month).get();

    for (var doc in snapshot.docs) {
      try {
        print("DOC ${doc.id}: ${doc.data()}");

        final item = Statistics.fromMap(doc.data(), doc.id);
        statistics.add(item);
      } catch (e) {
        print("❌ Lỗi ${doc.id}: $e");
        continue;
      }
    }
    return statistics;
  }
  
  Future<List<Statistics?>> getStatisticsYears() async {
    List<Statistics?> years = [];
    final doc = await Collections.statistics.get();

    for (var i in doc.docs) {
      try {
        years.add(Statistics.fromMap(i.data(), i.id));
      } catch (e) {
        print(e);
      }
    }

    return years;
  }
}
