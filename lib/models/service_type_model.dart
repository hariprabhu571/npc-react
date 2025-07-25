class ServiceTypeData {
  String typeName;
  List<PricingField> pricingFields;
  int? id; // Database ID for existing service types

  ServiceTypeData({
    required this.typeName,
    required this.pricingFields,
    this.id,
  });

  // Create a deep copy
  ServiceTypeData clone() {
    return ServiceTypeData(
      typeName: typeName,
      pricingFields: pricingFields.map((field) => field.clone()).toList(),
      id: id,
    );
  }

  // Convert from JSON map
  factory ServiceTypeData.fromJson(Map<String, dynamic> json) {
    return ServiceTypeData(
      typeName: json['service_type_name'],
      id: json['service_type_id'] != null ? int.parse(json['service_type_id'].toString()) : null,
      pricingFields: (json['pricing_fields'] as List<dynamic>)
          .map((field) => PricingField.fromJson(field))
          .toList(),
    );
  }

  // Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'service_type_name': typeName,
      'service_type_id': id,
      'pricing_fields': pricingFields.map((field) => field.toJson()).toList(),
    };
  }
}

class PricingField {
  String roomSize;
  String price;
  int? id; // Database ID for existing fields

  PricingField({
    required this.roomSize,
    required this.price,
    this.id,
  });

  // Create a deep copy
  PricingField clone() {
    return PricingField(
      roomSize: roomSize,
      price: price,
      id: id,
    );
  }

  // Convert from JSON map
  factory PricingField.fromJson(Map<String, dynamic> json) {
    return PricingField(
      roomSize: json['room_size'],
      price: json['price'].toString(),
      id: json['pricing_field_id'] != null ? int.parse(json['pricing_field_id'].toString()) : null,
    );
  }

  // Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'room_size': roomSize,
      'price': price,
      'pricing_field_id': id,
    };
  }
}