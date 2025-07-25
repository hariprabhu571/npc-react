import 'package:flutter/material.dart';
import '../models/service_type_model.dart';

class ServiceTypeCard extends StatelessWidget {
  final ServiceTypeData serviceType;
  final Function(String) onTypeNameChanged;
  final Function(int, String) onRoomSizeChanged;
  final Function(int, String) onPriceChanged;
  final Function() onAddField;
  final Function(int) onRemoveField;
  final Function() onRemoveType;
  final bool canRemoveType;

  const ServiceTypeCard({
    Key? key,
    required this.serviceType,
    required this.onTypeNameChanged,
    required this.onRoomSizeChanged,
    required this.onPriceChanged,
    required this.onAddField,
    required this.onRemoveField,
    required this.onRemoveType,
    required this.canRemoveType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Type Name
            const Text(
              'Space Type:',
              style: TextStyle(fontSize: 14, fontFamily: 'sora'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: serviceType.typeName)..selection = TextSelection.fromPosition(
                TextPosition(offset: serviceType.typeName.length),
              ),
              onChanged: onTypeNameChanged,
              decoration: InputDecoration(
                hintText: 'Enter Space Type (e.g., Residential)',
                hintStyle: TextStyle(
                    fontFamily: 'sora',
                    color: const Color(0xFF000000).withOpacity(0.2),
                    fontSize: 12
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pricing Fields Header
            const Text(
              'Pricing Fields:',
              style: TextStyle(fontSize: 14, fontFamily: 'sora'),
            ),
            const SizedBox(height: 8),

            // Pricing Fields List
            ...serviceType.pricingFields.asMap().entries.map((entry) {
              int fieldIndex = entry.key;
              PricingField field = entry.value;

              return Column(
                children: [
                  Row(
                    children: [
                      // Room Size Input
                      Expanded(
                        flex: 4,
                        child: TextField(
                          controller: TextEditingController(text: field.roomSize)..selection = TextSelection.fromPosition(
                            TextPosition(offset: field.roomSize.length),
                          ),
                          onChanged: (value) => onRoomSizeChanged(fieldIndex, value),
                          decoration: InputDecoration(
                            hintText: 'Room Size (e.g., 1BHK)',
                            hintStyle: TextStyle(
                                fontFamily: 'sora',
                                color: const Color(0xFF000000).withOpacity(0.2),
                                fontSize: 12
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Price Input
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: TextEditingController(text: field.price)..selection = TextSelection.fromPosition(
                            TextPosition(offset: field.price.length),
                          ),
                          onChanged: (value) => onPriceChanged(fieldIndex, value),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '₹',
                            hintStyle: TextStyle(
                                fontFamily: 'sora',
                                color: const Color(0xFF000000).withOpacity(0.2),
                                fontSize: 16
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Remove Field Button
                      IconButton(
                        onPressed: serviceType.pricingFields.length > 1
                            ? () => onRemoveField(fieldIndex)
                            : null,
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        tooltip: 'Remove this pricing field',
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                ],
              );
            }).toList(),

            // Add Field Button
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddField,
                icon: const Icon(Icons.add, color: Colors.green, size: 16),
                label: const Text(
                  'Add Field',
                  style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'sora',
                      fontSize: 14
                  ),
                ),
              ),
            ),

            // Remove Space Type Button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: canRemoveType ? onRemoveType : null,
                icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                label: const Text(
                  'Remove Space Type',
                  style: TextStyle(
                      color: Colors.red,
                      fontFamily: 'sora',
                      fontSize: 12
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}