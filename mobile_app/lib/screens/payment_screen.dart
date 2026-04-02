import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';
import 'package:flutter/services.dart';
import 'transaction_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Product product;
  final String type;
  final double? finalPriceOverride;

  const PaymentScreen({
    Key? key,
    required this.product,
    required this.type,
    this.finalPriceOverride,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  File? _proofImage;
  final _picker = ImagePicker();
  final _utrController = TextEditingController();

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _proofImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadProof(File image) async {
    try {
      final fileName = 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'payment_proofs/$fileName';

      await Supabase.instance.client.storage.from('donations').upload(
        path,
        image,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      return Supabase.instance.client.storage.from('donations').getPublicUrl(path);
    } catch (e) {
      debugPrint("Upload failed: $e");
      return null;
    }
  }

  Future<void> _confirmPayment() async {
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a screenshot of your payment')));
      return;
    }
    if (_utrController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your Transaction ID / UTR number')));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) throw Exception('Session expired. Please login again.');

      final proofUrl = await _uploadProof(_proofImage!);
      
      final paymentAmount = widget.type == 'membership' ? 99.0 : (widget.finalPriceOverride ?? widget.product.price);

      String txType = 'sale';
      if (widget.type == 'membership') {
        txType = 'membership';
      } else if (widget.product.isAuction) {
        txType = 'auction';
      } else if (widget.product.price == 0) {
        txType = 'donation_request';
      }

      final tx = await Provider.of<TransactionProvider>(context, listen: false).createTransaction(
        userId: user.id,
        donationId: widget.product.id,
        amount: paymentAmount,
        type: txType,
        paymentRef: proofUrl ?? 'REF_${DateTime.now().millisecondsSinceEpoch}',
        utrNumber: _utrController.text.trim(),
        sellerId: widget.product.donorId,
      );

      // Update product status to reserved if it's a purchase/donation request
      if (widget.type != 'membership') {
        await Provider.of<ProductProvider>(context, listen: false).updateProductStatus(widget.product.id, 'pending_approval');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment details submitted successfully!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionSuccessScreen(
            amount: paymentAmount,
            itemTitle: widget.type == 'membership' ? 'Unideal Membership' : widget.product.title,
            transaction: tx,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request Failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Confirm Transaction', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressIndicator(),
            const SizedBox(height: 24),
            
            // QR Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo[900]!, Colors.indigo[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  Text(
                    widget.type == 'membership' ? 'Donate ₹99 to Become Premium' : 'Pay to Secure Item',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  if (widget.type != 'membership')
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Funds will be held in Escrow for your safety.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: QrImageView(
                      data: 'upi://pay?pa=${AppConstants.upiId}&pn=Unideal&am=${widget.type == 'membership' ? 99 : 0}&tn=${widget.product.title}',
                      version: QrVersions.auto,
                      size: 160.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildUpiCopySection(),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, color: Colors.white70, size: 14),
                      SizedBox(width: 4),
                      Text('Secure UPI Payment', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            // Safety Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.amber[800]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Escrow Payment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[900],
                          ),
                        ),
                        Text(
                          'Money is held by Unideal until you receive the item and share the OTP with the seller.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Transaction Details'),
            const SizedBox(height: 12),
            TextField(
              controller: _utrController,
              decoration: InputDecoration(
                hintText: 'Enter 12-digit UTR or Transaction ID',
                prefixIcon: const Icon(Icons.numbers, color: Colors.indigo),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.indigo.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.indigo.withOpacity(0.1)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Upload Payment Screenshot'),
            const SizedBox(height: 12),
            _buildUploadArea(),
            
            const SizedBox(height: 40),
            _buildSubmitButton(),
            const SizedBox(height: 16),
            _buildTrustFooter(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStep(1, 'Pay via UPI', isDone: true),
        _buildStepLine(true),
        _buildStep(2, 'Upload', isActive: _proofImage == null, isDone: _proofImage != null),
        _buildStepLine(_proofImage != null),
        _buildStep(3, 'Verify'),
      ],
    );
  }

  Widget _buildStep(int number, String label, {bool isDone = false, bool isActive = false}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isDone ? Colors.green : (isActive ? Colors.indigo : Colors.grey[300]),
          child: isDone 
            ? const Icon(Icons.check, size: 16, color: Colors.white) 
            : Text(number.toString(), style: TextStyle(fontSize: 12, color: isActive ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: isDone || isActive ? Colors.black87 : Colors.grey[500], fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? Colors.green : Colors.grey[200],
      ),
    );
  }

  Widget _buildUpiCopySection() {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(const ClipboardData(text: AppConstants.upiId));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID Copied!'), duration: Duration(seconds: 1)));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppConstants.upiId, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.copy, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _proofImage != null ? Colors.green.withOpacity(0.02) : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _proofImage != null ? Colors.green : Colors.indigo.withOpacity(0.1),
            width: 1.5,
            style: BorderStyle.solid, // Flutter doesn't natively support dashed easily without painter
          ),
        ),
        child: _proofImage != null
            ? Stack(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_proofImage!, fit: BoxFit.cover, width: double.infinity)),
                  const Positioned(
                    right: 8, top: 8,
                    child: CircleAvatar(backgroundColor: Colors.green, radius: 12, child: Icon(Icons.check, size: 14, color: Colors.white)),
                  )
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.file_upload, color: Colors.indigo, size: 36),
                  SizedBox(height: 12),
                  Text('Tap to Upload Payment Screenshot', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500)),
                  Text('JPG or PNG supported', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: _proofImage == null ? null : _confirmPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[200],
                disabledForegroundColor: Colors.grey[400],
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: _proofImage == null ? 0 : 8,
                shadowColor: Colors.indigo.withOpacity(0.4)
              ),
              child: const Text('VERIFY PAYMENT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
    );
  }

  Widget _buildTrustFooter() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 14, color: Colors.grey),
            SizedBox(width: 4),
            Text('🔒 Secure Payment • Powered by UPI', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Text('Refer to our Refund Policy in Help section.', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
      ],
    );
  }
}
