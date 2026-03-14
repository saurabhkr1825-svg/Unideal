import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Add dependency if missed or format manually
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transaction_model.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        Provider.of<TransactionProvider>(context, listen: false).fetchTransactions(user.id);
      }
    });
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
            return Center(child: CircularProgressIndicator());
          }
          
          if (transactionProvider.transactions.isEmpty) {
            return Center(child: Text('No transactions yet.', style: TextStyle(color: Colors.grey)));
          }

          final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.id;
          
          final buyingTransactions = transactionProvider.transactions.where((tx) => tx.userId == currentUserId).toList();
          final sellingTransactions = transactionProvider.transactions.where((tx) => tx.sellerId == currentUserId && tx.type != 'membership').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTransactionList(buyingTransactions, true),
              _buildTransactionList(sellingTransactions, false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionList(List<TransactionModel> transactions, bool isBuyer) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          isBuyer ? 'No purchases yet.' : 'No sales yet.', 
          style: const TextStyle(color: Colors.grey)
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: transactions.length,
      itemBuilder: (ctx, i) {
        final tx = transactions[i];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
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
                        color: tx.status == 'completed' ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tx.status.toUpperCase(),
                        style: TextStyle(
                          color: tx.status == 'completed' ? Colors.green[700] : Colors.orange[700],
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
      },
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
    final TextEditingController _otpController = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Verify Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  hintText: 'Enter Buyer OTP',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                try {
                  final success = await Provider.of<TransactionProvider>(context, listen: false)
                      .verifyOTP(tx.id, _otpController.text.trim(), tx.sellerId!);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP Verified! Please enter your payment details.'), backgroundColor: Colors.green));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP. Please try again.'), backgroundColor: Colors.red));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
                }
              },
              child: Text('Verify'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSellerPaymentDetailsSection(TransactionModel tx) {
    final _upiController = TextEditingController();
    final _phoneController = TextEditingController();
    String _selectedMethod = 'UPI';

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Action Required: Request Fund Release', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            SizedBox(height: 8),
            Text('OTP verified successfully. Where should we send your funds?', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            SizedBox(height: 12),
            Row(
              children: [
                ChoiceChip(
                  label: Text('UPI'),
                  selected: _selectedMethod == 'UPI',
                  onSelected: (val) => setState(() => _selectedMethod = 'UPI'),
                  selectedColor: Colors.indigo[100],
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Bank Transfer'),
                  selected: _selectedMethod == 'Bank Transfer',
                  onSelected: (val) => setState(() => _selectedMethod = 'Bank Transfer'),
                  selectedColor: Colors.indigo[100],
                ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: _upiController,
              decoration: InputDecoration(hintText: _selectedMethod == 'UPI' ? 'Your UPI ID (e.g. name@okaxis)' : 'Account Details/IFSC', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(hintText: 'Your Phone Number', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_upiController.text.isEmpty || _phoneController.text.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all details')));
                     return;
                  }
                  try {
                    await Provider.of<TransactionProvider>(context, listen: false).updateSellerPaymentDetails(
                      tx.id,
                      _selectedMethod,
                      tx.sellerId!,
                      upi: _upiController.text.trim(),
                      phone: _phoneController.text.trim()
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Details submitted! Admin will release funds soon.'), backgroundColor: Colors.indigo));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
                    }
                  }
                },
                child: Text('Submit Request'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildSellerPaymentDetailsSummary() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(Icons.hourglass_bottom, color: Colors.orange[800], size: 16),
          SizedBox(width: 8),
          Expanded(child: Text('Payment details submitted. Waiting for Admin to release funds.', style: TextStyle(fontSize: 12, color: Colors.orange[900], fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
