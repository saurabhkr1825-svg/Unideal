import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../services/supabase_membership_service.dart';
import 'home_screen.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  _MembershipScreenState createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final SupabaseMembershipService _membershipService = SupabaseMembershipService();
  final TextEditingController _txnController = TextEditingController();
  File? _screenshot;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _screenshot = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_screenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a screenshot')));
      return;
    }
    if (_txnController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Transaction ID')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _membershipService.submitMembershipRequest(
        planName: 'Premium Monthly',
        amount: AppConstants.membershipPrice,
        txnId: _txnController.text.trim(),
        utrNumber: _txnController.text.trim(),
        screenshot: _screenshot!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Membership Request Submitted! ✅\nOur team is verifying your payment. It usually takes 2-4 hours.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Membership Plan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Gradient Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo[900]!, Colors.purple[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 60),
                  ),
                  const SizedBox(height: 20),
                  const Text('UNIDEAL PREMIUM', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 10),
                  const Text('Unlock the power to save lives and connect with donors directly.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Only ', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        Text('₹${AppConstants.membershipPrice.toStringAsFixed(0)}', style: TextStyle(color: Colors.indigo[900], fontSize: 28, fontWeight: FontWeight.w900)),
                        Text(' / One-time', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildBenefitItem(Icons.chat_rounded, 'Direct Chat', 'Message donors instantly to request items.'),
                  _buildBenefitItem(Icons.verified_user_rounded, 'Priority Badge', 'Get a verified badge on your profile.'),
                  _buildBenefitItem(Icons.history_edu_rounded, 'Early Access', 'Be the first to see high-value donation items.'),
                  
                  const SizedBox(height: 40),
                  const Text('Scan to Pay via UPI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.indigo.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(25),
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
                    ),
                    child: QrImageView(
                      data: 'upi://pay?pa=${AppConstants.upiId}&pn=Unideal&am=${AppConstants.membershipPrice}&tn=Membership',
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Step 2: Upload Proof', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _txnController,
                    decoration: InputDecoration(
                      labelText: 'Transaction ID / UTR',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.indigo.withOpacity(0.1)),
                      ),
                      child: _screenshot == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo, color: Colors.indigo, size: 40),
                                const SizedBox(height: 8),
                                Text('Upload Payment Screenshot', style: TextStyle(color: Colors.grey[600])),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(_screenshot!, fit: BoxFit.cover),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: _isSubmitting
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _submitRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 8,
                              shadowColor: Colors.indigo.withOpacity(0.4)
                            ),
                            child: const Text('SUBMIT PROOF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                          ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Payments are manually verified by our team.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.indigo[50], child: Icon(icon, color: Colors.indigo, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
