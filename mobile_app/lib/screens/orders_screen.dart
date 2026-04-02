import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Add dependency if missed or format manually
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transaction_model.dart';
import '../models/purchase_request_model.dart';
import '../services/supabase_purchase_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PurchaseRequest> _myRequests = [];
  List<PurchaseRequest> _incomingRequests = [];
  bool _isRequestsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    setState(() => _isRequestsLoading = true);
    
    // Fetch legacy transactions
    Provider.of<TransactionProvider>(context, listen: false).fetchTransactions(user.id);
    
    // Fetch new purchase requests
    try {
      final sent = await SupabasePurchaseService().getMySentRequests(user.id);
      final incoming = await SupabasePurchaseService().getIncomingRequests(user.id);
      if (mounted) {
        setState(() {
          _myRequests = sent;
          _incomingRequests = incoming;
          _isRequestsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isRequestsLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Buying'),
            Tab(text: 'Selling'),
          ],
        ),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, _) {
          if (transactionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.id;
          
          final buyingTransactions = transactionProvider.transactions.where((tx) => tx.userId == currentUserId).toList();
          final sellingTransactions = transactionProvider.transactions.where((tx) => tx.sellerId == currentUserId && tx.type != 'membership').toList();

          if (buyingTransactions.isEmpty && sellingTransactions.isEmpty && _myRequests.isEmpty && _incomingRequests.isEmpty && !transactionProvider.isLoading && !_isRequestsLoading) {
            return const Center(child: Text('No orders or requests yet.', style: TextStyle(color: Colors.grey)));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  children: [
                    if (_myRequests.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('PURCHASE REQUESTS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      ..._myRequests.map((req) => _buildPurchaseRequestCard(req, true)),
                    ],
                    if (buyingTransactions.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('PAST TRANSACTIONS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      ...buyingTransactions.map((tx) => _buildTransactionCard(tx, true)),
                    ],
                    if (_myRequests.isEmpty && buyingTransactions.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No buying activity yet.', style: TextStyle(color: Colors.grey)))),
                  ],
                ),
              ),
              RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  children: [
                    if (_incomingRequests.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('INCOMING BUY REQUESTS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      ),
                      ..._incomingRequests.map((req) => _buildPurchaseRequestCard(req, false)),
                    ],
                    if (sellingTransactions.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('PAST SALES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      ...sellingTransactions.map((tx) => _buildTransactionCard(tx, false)),
                    ],
                    if (_incomingRequests.isEmpty && sellingTransactions.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No selling activity yet.', style: TextStyle(color: Colors.grey)))),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPurchaseRequestCard(PurchaseRequest req, bool isBuyer) {
    Color statusColor = Colors.orange;
    if (req.status == 'accepted') statusColor = Colors.green;
    if (req.status == 'rejected') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        title: Text(req.productTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(isBuyer ? 'Request Sent' : 'Request from ${req.buyerName ?? "Student"}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(req.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _buildInfoRow('Hostel', req.hostelName),
                _buildInfoRow('Room', req.roomNo),
                _buildInfoRow('Meeting Point', req.meetingPoint),
                if (req.phone != null) _buildInfoRow('Contact', req.phone!),
                const SizedBox(height: 16),
                if (!isBuyer && req.status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateRequest(req, 'rejected'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('REJECT'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateRequest(req, 'accepted'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          child: const Text('ACCEPT'),
                        ),
                      ),
                    ],
                  ),
                if (req.status == 'accepted')
                  const Center(
                    child: Text('✅ Deal Approved. Meet offline to exchange.', 
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _updateRequest(PurchaseRequest req, String status) async {
    try {
      await SupabasePurchaseService().updateRequestStatus(req.id, req.productId, req.buyerId, status);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request $status!'), backgroundColor: status == 'accepted' ? Colors.green : Colors.orange));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx, bool isBuyer) {
    return _buildLegacyTransactionItem(tx, isBuyer); // Re-using existing card logic or similar
  }

  Widget _buildLegacyTransactionItem(TransactionModel tx, bool isBuyer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tx.status == 'completed' ? Colors.green[50] : (tx.status.contains('rejected') || tx.status == 'failed' ? Colors.red[50] : Colors.orange[50]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tx.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: tx.status == 'completed' ? Colors.green[700] : (tx.status.contains('rejected') || tx.status == 'failed' ? Colors.red[700] : Colors.orange[700]),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                Text(
                  DateFormat('dd MMM, yyyy').format(tx.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tx.itemTitle ?? tx.type.toUpperCase(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildProgressIndicator(tx),
            
            const Divider(height: 32),

            if (isBuyer && tx.status == 'pending' && !tx.otpVerified && tx.otp != null)
              _buildBuyerOtpSection(tx.otp!),
            
            if (isBuyer && tx.status == 'payment_verifying')
              _buildWaitingMsg('Payment under review by Admin. OTP will appear here once verified.'),

            if (!isBuyer && tx.status == 'payment_verifying')
              _buildWaitingMsg('Buyer has paid. Waiting for Admin to verify payment before you can deliver.'),

            if (!isBuyer && tx.status == 'pending' && !tx.otpVerified)
              _buildSellerVerificationSection(tx),

            if (!isBuyer && tx.status == 'pending' && tx.otpVerified && tx.sellerPaymentMethod == null)
              _buildSellerPaymentDetailsSection(tx),
            
            if (!isBuyer && tx.status == 'waiting_admin_approval')
               _buildSellerPaymentDetailsSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerOtpSection(String otp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[900]!, Colors.indigo[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'YOUR TRANSACTION OTP',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              otp,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 10,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Give this OTP to the seller ONLY after you have received the item.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(TransactionModel tx) {
    int currentStep = 0;
    if (tx.status == 'pending') {
      if (tx.otpVerified) {
        currentStep = 2; // OTP Confirmed
      } else {
        currentStep = 1; // Payment verified
      }
    } else if (tx.status == 'waiting_admin_approval') {
      currentStep = 3;
    } else if (tx.status == 'completed') {
      currentStep = 4;
    }

    final steps = ['Payment\nSubmitted', 'Payment\nVerified', 'OTP\nConfirmed', 'Admin\nApproval'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentStep;
        final isActive = index == currentStep;
        
        return Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.indigo : Colors.grey[200],
                shape: BoxShape.circle,
                border: isActive ? Border.all(color: Colors.indigo[200]!, width: 4) : null,
              ),
              child: isCompleted 
                ? const Icon(Icons.check, size: 14, color: Colors.white) 
                : Center(child: Text('${index + 1}', style: TextStyle(fontSize: 10, color: Colors.grey[600]))),
            ),
            const SizedBox(height: 4),
            Text(
              steps[index],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                color: isCompleted ? Colors.indigo : Colors.grey,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildWaitingMsg(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: Colors.orange[800], size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: TextStyle(fontSize: 12, color: Colors.orange[900]))),
        ],
      ),
    );
  }

  Widget _buildSellerVerificationSection(TransactionModel tx) {
    final TextEditingController otpController = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Verify Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: otpController,
                decoration: InputDecoration(
                  hintText: 'Enter Buyer OTP',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                try {
                  final success = await Provider.of<TransactionProvider>(context, listen: false)
                      .verifyOTP(tx.id, otpController.text.trim(), tx.sellerId!);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP Verified! Please enter your payment details.'), backgroundColor: Colors.green));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP. Please try again.'), backgroundColor: Colors.red));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Verify'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSellerPaymentDetailsSection(TransactionModel tx) {
    final upiController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedMethod = 'UPI';

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Action Required: Request Fund Release', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            Text('OTP verified successfully. Where should we send your funds?', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 12),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('UPI'),
                  selected: selectedMethod == 'UPI',
                  onSelected: (val) => setState(() => selectedMethod = 'UPI'),
                  selectedColor: Colors.indigo[100],
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Bank Transfer'),
                  selected: selectedMethod == 'Bank Transfer',
                  onSelected: (val) => setState(() => selectedMethod = 'Bank Transfer'),
                  selectedColor: Colors.indigo[100],
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: upiController,
              decoration: InputDecoration(hintText: selectedMethod == 'UPI' ? 'Your UPI ID (e.g. name@okaxis)' : 'Account Details/IFSC', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(hintText: 'Your Phone Number', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (upiController.text.isEmpty || phoneController.text.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all details')));
                     return;
                  }
                  try {
                    await Provider.of<TransactionProvider>(context, listen: false).updateSellerPaymentDetails(
                      tx.id,
                      selectedMethod,
                      tx.sellerId!,
                      upi: upiController.text.trim(),
                      phone: phoneController.text.trim()
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details submitted! Admin will release funds soon.'), backgroundColor: Colors.indigo));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                child: const Text('Submit Request'),
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildSellerPaymentDetailsSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(Icons.hourglass_bottom, color: Colors.orange[800], size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text('Payment details submitted. Waiting for Admin to release funds.', style: TextStyle(fontSize: 12, color: Colors.orange[900], fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
