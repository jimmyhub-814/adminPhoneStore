import 'package:admin/models/variant.dart';
import 'package:flutter/material.dart';

class Product extends ChangeNotifier {
  static const idField = 'id';
  static const categoryIdField = 'categoryId';
  static const listVariantsField = 'listVariants';
  static const extraImagesField = 'extraImages';
  static const mainImageField = 'mainImage';
  static const titleField = 'title';
  static const phoneDescriptionField = 'phoneDescription';
  static const salesVolumeField = 'salesVolume';
  static const fbInfoField = 'fbInfo';

  String id;
  String categoryId;
  List<Variants> listVariants;
  List<String> extraImages;
  String mainImage;
  String title;
  String phoneDescription;
  int salesVolume;
  FeedbackInfo fbInfo;

  Product({
    required this.id,
    required this.categoryId,
    required this.listVariants,
    this.extraImages = const [],
    required this.mainImage,
    required this.title,
    required this.phoneDescription,
    required this.salesVolume,
    required this.fbInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      idField: id,
      categoryIdField: categoryId,
      listVariantsField: listVariants.map((v) => v.toMap()).toList(),
      extraImagesField:
          extraImages.isEmpty ? [] : extraImages.map((e) => e).toList(),
      mainImageField: mainImage,
      titleField: title,
      phoneDescriptionField: phoneDescription,
      salesVolumeField: salesVolume,
      fbInfoField: fbInfo.toMap(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    return Product(
        id: map[idField] as String? ?? '',
        categoryId: map[categoryIdField] ?? '',
        listVariants: (map[listVariantsField] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((v) => Variants.fromMap(Map<String, dynamic>.from(v)))
            .toList(),
        extraImages: (map[extraImagesField] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        mainImage: map[mainImageField] ?? '',
        title: map[titleField] ?? '',
        phoneDescription: map[phoneDescriptionField] ?? '',
        salesVolume: map[salesVolumeField] as int? ?? 0,
        fbInfo: FeedbackInfo.fromMap(map[fbInfoField]));
  }
}

class FeedbackInfo extends ChangeNotifier {
  static const averageRatingField = 'averageRating';
  static const totalRatingField = 'totalRating';
  static const sumRatingField = 'sumRating';
  
  double averageRating;
  int totalRating;
  int sumRating;

  FeedbackInfo({
    required this.averageRating,
    required this.totalRating,
    required this.sumRating,
  });

  Map<String, dynamic> toMap() {
    return {
      averageRatingField: averageRating,
      totalRatingField: totalRating,
      sumRatingField: sumRating,
    };
  }

  factory FeedbackInfo.fromMap(Map<String, dynamic> map) {
    return FeedbackInfo(
      averageRating: (map[averageRatingField] as num?)?.toDouble() ?? 0.0,
      totalRating: map[totalRatingField] as int? ?? 0,
      sumRating: map[sumRatingField] as int? ?? 0,
    );
  }
}
