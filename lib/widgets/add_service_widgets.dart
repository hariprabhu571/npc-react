import 'package:flutter/material.dart';

class ServiceWidgets {
  static Widget buildOrderSummary(List<Map<String, dynamic>> cartItems) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: Color(0xFF0F766E), size: 24),
                SizedBox(width: 12),
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    fontFamily: 'sora',
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Color(0xFFE2E8F0)),
          ...cartItems.map((item) => Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['service_type_name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                          fontFamily: 'sora',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        item['room_size'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontFamily: 'sora',
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${item['quantity']}x',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                    fontFamily: 'sora',
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  '₹${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F766E),
                    fontFamily: 'sora',
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  static Widget buildAddressSection(
      TextEditingController addressController,
      bool hasAddress,
      VoidCallback updateAddress,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFF0F766E), size: 24),
                SizedBox(width: 12),
                Text(
                  'Service Address',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    fontFamily: 'sora',
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: addressController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Enter your complete address',
                prefixIcon: Icon(Icons.home_outlined, color: Color(0xFF0F766E)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF0F766E)),
                ),
              ),
            ),
            if (!hasAddress) ...[
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: updateAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Save Address'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget buildServiceSchedule(
      DateTime? selectedDate,
      String selectedTimeSlot,
      List<String> timeSlots,
      VoidCallback selectDate,
      Function(String) onTimeSlotSelected,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Color(0xFF0F766E), size: 24),
                SizedBox(width: 12),
                Text(
                  'Service Schedule',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    fontFamily: 'sora',
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Date Selection
            InkWell(
              onTap: selectDate,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Color(0xFF0F766E)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Date',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                              fontFamily: 'sora',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            selectedDate != null
                                ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                                : 'Select Date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                              fontFamily: 'sora',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Color(0xFF6B7280), size: 16),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Time Slot Selection
            Text(
              'Select Time Slot',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                fontFamily: 'sora',
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: timeSlots.map((slot) => GestureDetector(
                onTap: () => onTimeSlotSelected(slot),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: selectedTimeSlot == slot
                        ? Color(0xFF0F766E)
                        : Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: selectedTimeSlot == slot
                          ? Color(0xFF0F766E)
                          : Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    slot,
                    style: TextStyle(
                      color: selectedTimeSlot == slot
                          ? Colors.white
                          : Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'sora',
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildCouponSection(
      bool isCouponApplied,
      TextEditingController couponController,
      String appliedCouponCode,
      double couponDiscount,
      VoidCallback applyCoupon,
      VoidCallback removeCoupon,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer, color: Color(0xFF0F766E), size: 24),
                SizedBox(width: 12),
                Text(
                  'Apply Coupon',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    fontFamily: 'sora',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            if (!isCouponApplied) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: couponController,
                      decoration: InputDecoration(
                        labelText: 'Enter coupon code',
                        prefixIcon: Icon(Icons.discount, color: Color(0xFF0F766E)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF0F766E)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: applyCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Apply'),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coupon Applied: $appliedCouponCode',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                              fontFamily: 'sora',
                            ),
                          ),
                          Text(
                            'You saved ₹${couponDiscount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF10B981),
                              fontFamily: 'sora',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: removeCoupon,
                      icon: Icon(Icons.close, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget buildPaymentMethod(
      List<Map<String, dynamic>> paymentMethods,
      String selectedPaymentMethod,
      Function(String) onPaymentMethodSelected,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Color(0xFF0F766E), size: 24),
                SizedBox(width: 12),
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    fontFamily: 'sora',
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ...paymentMethods.map((method) => GestureDetector(
              onTap: () => onPaymentMethodSelected(method['id']),
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selectedPaymentMethod == method['id']
                      ? Color(0xFF0F766E).withOpacity(0.1)
                      : Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedPaymentMethod == method['id']
                        ? Color(0xFF0F766E)
                        : Color(0xFFE2E8F0),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedPaymentMethod == method['id']
                            ? Color(0xFF0F766E)
                            : Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        method['icon'],
                        color: selectedPaymentMethod == method['id']
                            ? Colors.white
                            : Color(0xFF6B7280),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['name'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                              fontFamily: 'sora',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            method['subtitle'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontFamily: 'sora',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedPaymentMethod == method['id'])
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF0F766E),
                        size: 24,
                      ),
                  ],
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  static Widget buildPriceBreakdown(
      double subtotal,
      double discount,
      bool isCouponApplied,
      double couponDiscount,
      double total,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: Color(0xFF0F766E), size: 24),
                SizedBox(width: 12),
                Text(
                  'Price Breakdown',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    fontFamily: 'sora',
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildPriceRow('Subtotal', subtotal, false),
            _buildPriceRow('Discount (15%)', -discount, false, isDiscount: true),
            if (isCouponApplied)
              _buildPriceRow('Coupon Discount', -couponDiscount, false, isDiscount: true),
            Divider(color: Color(0xFFE2E8F0), thickness: 1),
            _buildPriceRow('Total Amount', total, true),
          ],
        ),
      ),
    );
  }

  static Widget _buildPriceRow(String label, double amount, bool isTotal, {bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: Color(0xFF1F2937),
              fontFamily: 'sora',
            ),
          ),
          Row(
            children: [
              if (isDiscount && amount < 0)
                Text(
                  '₹${(-amount).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: isTotal ? 18 : 16,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                    color: Color(0xFF6B7280),
                    decoration: TextDecoration.lineThrough,
                    fontFamily: 'sora',
                  ),
                ),
              SizedBox(width: 8),
              Text(
                '${isDiscount ? '-' : ''}₹${amount.abs().toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                  color: isTotal
                      ? Color(0xFF0F766E)
                      : isDiscount
                      ? Color(0xFF10B981)
                      : Color(0xFF1F2937),
                  fontFamily: 'sora',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildSpecialInstructions(TextEditingController notesController) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_outlined, color: Color(0xFF0F766E), size: 24),
                SizedBox(width: 12),
                Text(
                  'Special Instructions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    fontFamily: 'sora',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Any special instructions for our team (Optional)',
                prefixIcon: Icon(Icons.edit_note, color: Color(0xFF0F766E)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF0F766E)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildTermsAndConditions(
      bool agreedToTerms,
      Function(bool) onTermsChanged,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gavel, color: Color(0xFF0F766E), size: 24),
                SizedBox(width: 12),
                Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    fontFamily: 'sora',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTermItem('• Service will be provided on the scheduled date and time'),
                  _buildTermItem('• Payment is due upon completion of service'),
                  _buildTermItem('• Cancellation must be made 24 hours in advance'),
                  _buildTermItem('• Additional charges may apply for extra requirements'),
                  _buildTermItem('• Service guarantee as per company policy'),
                ],
              ),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: () => onTermsChanged(!agreedToTerms),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: agreedToTerms ? Color(0xFF0F766E) : Colors.white,
                      border: Border.all(
                        color: agreedToTerms ? Color(0xFF0F766E) : Color(0xFFE2E8F0),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: agreedToTerms
                        ? Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'I agree to the terms and conditions and privacy policy',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                        fontFamily: 'sora',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTermItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF6B7280),
          fontFamily: 'sora',
          height: 1.4,
        ),
      ),
    );
  }
}