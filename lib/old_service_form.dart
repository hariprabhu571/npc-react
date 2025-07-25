import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/service_type_model.dart';
import 'services/service_api.dart';
import 'widgets/service_type_card.dart';

class ServiceTypeManager extends StatefulWidget {
  final String serviceName;
  final bool isEditing;

  const ServiceTypeManager({
    Key? key,
    required this.serviceName,
    this.isEditing = false,
  }) : super(key: key);

  @override
  _ServiceTypeManagerState createState() => _ServiceTypeManagerState();
}

class _ServiceTypeManagerState extends State<ServiceTypeManager> {
  List<ServiceTypeData> serviceTypes = [];
  List<ServiceTypeData> originalServiceTypes = []; // To track changes for deletion
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _errorMessage;
  final ServiceApi _serviceApi = ServiceApi();

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _fetchExistingServiceData();
    } else {
      // Add an empty service type for new creation
      serviceTypes.add(ServiceTypeData(typeName: '', pricingFields: [PricingField(roomSize: '', price: '', id: null)], id: null));
      _isInitialLoading = false;
    }
  }

  Future<void> _fetchExistingServiceData() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _serviceApi.fetchServiceDetails(widget.serviceName);

      if (result.isSuccess) {
        setState(() {
          if (result.data!.isEmpty) {
            // If no data found, add an empty service type
            serviceTypes = [ServiceTypeData(typeName: '', pricingFields: [PricingField(roomSize: '', price: '', id: null)], id: null)];
          } else {
            serviceTypes = result.data!;
            // Create a deep copy of original data for comparison later
            originalServiceTypes = serviceTypes.map((type) => type.clone()).toList();
          }
        });
      } else {
        setState(() {
          _errorMessage = result.errorMessage;
          // Add an empty service type as fallback
          serviceTypes = [ServiceTypeData(typeName: '', pricingFields: [PricingField(roomSize: '', price: '', id: null)], id: null)];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: $e";
        // Add an empty service type as fallback
        serviceTypes = [ServiceTypeData(typeName: '', pricingFields: [PricingField(roomSize: '', price: '', id: null)], id: null)];
      });
    } finally {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _submitServiceTypes() async {
    // Validate input
    for (var serviceType in serviceTypes) {
      if (serviceType.typeName.trim().isEmpty) {
        _showErrorSnackBar("Service type name cannot be empty");
        return;
      }

      for (var field in serviceType.pricingFields) {
        if (field.roomSize.trim().isEmpty) {
          _showErrorSnackBar("Room size cannot be empty");
          return;
        }
        if (field.price.trim().isEmpty) {
          _showErrorSnackBar("Price cannot be empty");
          return;
        }

        // Validate price is a number
        try {
          double.parse(field.price);
        } catch (e) {
          _showErrorSnackBar("Price must be a valid number");
          return;
        }
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.isEditing) {
        // Handle updates (additions, modifications, deletions)

        // 1. Find service types to delete
        final servicesToDelete = originalServiceTypes.where((original) =>
        !serviceTypes.any((current) => current.id == original.id)
        ).toList();

        // 2. Delete service types that were removed
        for (var serviceType in servicesToDelete) {
          if (serviceType.id != null) {
            final deleteResult = await _serviceApi.deleteServiceType(serviceType.id!.toString());
            if (!deleteResult.isSuccess) {
              _showErrorSnackBar("Failed to delete service type: ${deleteResult.errorMessage}");
              print("${deleteResult.errorMessage}");
              return;
            }
          }
        }

        // 3. For each current service type, handle pricing fields
        for (var serviceType in serviceTypes) {
          // If this is a new service type (no ID), add it
          if (serviceType.id == null) {
            final addResult = await _serviceApi.addServiceType(
                widget.serviceName,
                serviceType.typeName,
                serviceType.pricingFields
            );

            if (!addResult.isSuccess) {
              _showErrorSnackBar("Failed to add service type: ${addResult.errorMessage}");
              return;
            }
            continue;
          }

          // Find the original service type to compare
          final originalType = originalServiceTypes.firstWhere(
                  (original) => original.id == serviceType.id,
              orElse: () => ServiceTypeData(typeName: '', pricingFields: [], id: null)
          );

          // If found in original, check for changes
          if (originalType.id != null) {
            // Handle service type name update if changed
            if (originalType.typeName != serviceType.typeName) {
              final updateResult = await _serviceApi.updateServiceTypeName(
                  serviceType.id!,
                  serviceType.typeName
              );

              if (!updateResult.isSuccess) {
                _showErrorSnackBar("Failed to update service type name: ${updateResult.errorMessage}");
                return;
              }
            }

            // Find pricing fields to delete
            final fieldsToDelete = originalType.pricingFields.where((original) =>
            !serviceType.pricingFields.any((current) => current.id == original.id)
            ).toList();

            // Delete removed pricing fields
            for (var field in fieldsToDelete) {
              if (field.id != null) {
                final deleteResult = await _serviceApi.deletePricingField(field.id!.toString());
                if (!deleteResult.isSuccess) {
                  _showErrorSnackBar("Failed to delete pricing field: ${deleteResult.errorMessage}");

                  // If this is the "last pricing field" error, handle it by deleting the entire service type
                  if (deleteResult.errorMessage?.contains("Cannot delete the last pricing field") == true) {
                    final serviceTypeResult = await _serviceApi.deleteServiceType(serviceType.id!.toString());
                    if (!serviceTypeResult.isSuccess) {
                      _showErrorSnackBar("Failed to delete service type: ${serviceTypeResult.errorMessage}");
                    }
                    break;
                  }
                  return;
                }
              }
            }

            // Update existing or add new pricing fields
            for (var field in serviceType.pricingFields) {
              if (field.id == null) {
                // Add new pricing field
                final addResult = await _serviceApi.addPricingField(
                    widget.serviceName,
                    serviceType.typeName,
                    field.roomSize,
                    field.price
                );

                if (!addResult.isSuccess) {
                  _showErrorSnackBar("Failed to add pricing field: ${addResult.errorMessage}");
                  return;
                }
              } else {
                // Find original field to check for changes
                final originalField = originalType.pricingFields.firstWhere(
                        (original) => original.id == field.id,
                    orElse: () => PricingField(roomSize: '', price: '', id: null)
                );

                // Update if changed
                if (originalField.roomSize != field.roomSize || originalField.price != field.price) {
                  final updateResult = await _serviceApi.updatePricingField(
                      field.id!,
                      field.roomSize,
                      field.price
                  );

                  if (!updateResult.isSuccess) {
                    _showErrorSnackBar("Failed to update pricing field: ${updateResult.errorMessage}");
                    return;
                  }
                }
              }
            }
          }
        }
      } else {
        // Simple add for new service types
        for (var serviceType in serviceTypes) {
          final result = await _serviceApi.addServiceType(
              widget.serviceName,
              serviceType.typeName,
              serviceType.pricingFields
          );

          if (!result.isSuccess) {
            _showErrorSnackBar("Failed to add service type: ${result.errorMessage}");
            return;
          }
        }
      }

      // If all submissions were successful
      _showSuccessSnackBar("Service types saved successfully!");

      // Clear the form or navigate back
      if (!widget.isEditing) {
        setState(() {
          serviceTypes = [ServiceTypeData(typeName: '', pricingFields: [PricingField(roomSize: '', price: '', id: null)], id: null)];
        });
      } else {
        Navigator.pop(context, true); // Return with success result
      }

    } catch (e) {
      _showErrorSnackBar("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addServiceType() {
    setState(() {
      serviceTypes.add(ServiceTypeData(
          typeName: '',
          pricingFields: [PricingField(roomSize: '', price: '', id: null)],
          id: null
      ));
    });
  }

  void _removeServiceType(int index) {
    setState(() {
      serviceTypes.removeAt(index);
      if (serviceTypes.isEmpty) {
        serviceTypes.add(ServiceTypeData(
            typeName: '',
            pricingFields: [PricingField(roomSize: '', price: '', id: null)],
            id: null
        ));
      }
    });
  }

  void _addPricingField(int serviceTypeIndex) {
    setState(() {
      serviceTypes[serviceTypeIndex].pricingFields.add(
          PricingField(roomSize: '', price: '', id: null)
      );
    });
  }

  void _removePricingField(int serviceTypeIndex, int fieldIndex) {
    setState(() {
      serviceTypes[serviceTypeIndex].pricingFields.removeAt(fieldIndex);
      if (serviceTypes[serviceTypeIndex].pricingFields.isEmpty) {
        serviceTypes[serviceTypeIndex].pricingFields.add(
            PricingField(roomSize: '', price: '', id: null)
        );
      }
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? "Edit ${widget.serviceName}" : "Add ${widget.serviceName} Types",
          style: const TextStyle(fontFamily: 'sora'),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.red.withOpacity(0.1),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontFamily: 'sora'),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: serviceTypes.length,
                    itemBuilder: (context, serviceTypeIndex) {
                      return ServiceTypeCard(
                        serviceType: serviceTypes[serviceTypeIndex],
                        onTypeNameChanged: (value) {
                          setState(() {
                            serviceTypes[serviceTypeIndex].typeName = value;
                          });
                        },
                        onRoomSizeChanged: (fieldIndex, value) {
                          setState(() {
                            serviceTypes[serviceTypeIndex].pricingFields[fieldIndex].roomSize = value;
                          });
                        },
                        onPriceChanged: (fieldIndex, value) {
                          setState(() {
                            serviceTypes[serviceTypeIndex].pricingFields[fieldIndex].price = value;
                          });
                        },
                        onAddField: () => _addPricingField(serviceTypeIndex),
                        onRemoveField: (fieldIndex) => _removePricingField(serviceTypeIndex, fieldIndex),
                        onRemoveType: () => _removeServiceType(serviceTypeIndex),
                        canRemoveType: serviceTypes.length > 1,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _addServiceType,
                  child: Row(
                    children: const [
                      Icon(Icons.add, color: Colors.green),
                      Text(
                        'Add Another Space Type',
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'sora'
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Submit Button
                Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitServiceTypes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(fontFamily: 'sora', color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}