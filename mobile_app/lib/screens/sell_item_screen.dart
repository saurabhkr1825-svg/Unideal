import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/auction_provider.dart';
import '../widgets/custom_buttons.dart';

class SellItemScreen extends StatefulWidget {
  const SellItemScreen({super.key});

  @override
  _SellItemScreenState createState() => _SellItemScreenState();
}

class _SellItemScreenState extends State<SellItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  String _listingType = 'Donate'; // Donate, Sell, Auction
  String _category = 'Electronics';
  String _condition = 'Good';
  int _auctionDurationHours = 24;

  Uint8List? _selectedImageBytes;
  String? _fileName;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _fileName = image.name;
        _imagePath = image.path;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a product photo'), backgroundColor: Colors.orange));
      return;
    }

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    try {
      final double priceVal = _listingType == 'Sell' || _listingType == 'Auction' 
          ? double.tryParse(_priceController.text) ?? 50.0 
          : 0.0;

      final productId = await Provider.of<ProductProvider>(context, listen: false).uploadProduct(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        condition: _condition,
        donorId: user.id, 
        imageBytes: _selectedImageBytes!,
        fileName: _fileName ?? 'image.jpg',
        isAuction: _listingType == 'Auction',
        price: priceVal,
      );
      
      if (_listingType == 'Auction') {
        await Provider.of<AuctionProvider>(context, listen: false).createAuction(
          itemId: productId,
          sellerId: user.id,
          startingPrice: priceVal,
          durationHours: _auctionDurationHours,
        );
      }
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Success!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('Your item has been listed and is pending review.', textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('List an Item', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Upload Section
              const Text('Product Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.indigo.withOpacity(0.1), width: 2),
                  ),
                  child: _selectedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18), 
                          child: kIsWeb 
                            ? Image.network(_imagePath!, fit: BoxFit.cover)
                            : Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined, color: Colors.indigo, size: 50),
                            const SizedBox(height: 8),
                            Text('Tap to select photo', style: TextStyle(color: Colors.indigo[300])),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 30),

              // Form Fields
              _buildSectionTitle('Basic Information'),
              _buildTextField(
                controller: _titleController,
                label: 'Item Title',
                hint: 'e.g. Scientific Calculator, Engineering Books',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descController,
                label: 'Description',
                hint: 'Tell us more about the item...',
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Details'),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Category',
                      value: _category,
                      items: ['Electronics', 'Books', 'Furniture', 'Clothing', 'Other'],
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Condition',
                      value: _condition,
                      items: ['New', 'Good', 'Fair', 'Poor'],
                      onChanged: (v) => setState(() => _condition = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Listing Type'),
              Row(
                children: ['Donate', 'Sell', 'Auction'].map((type) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: _listingType == type,
                      onSelected: (val) => setState(() => _listingType = type),
                      selectedColor: Colors.indigo,
                      labelStyle: TextStyle(color: _listingType == type ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ),
                )).toList(),
              ),
              if (_listingType != 'Donate')
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: _buildTextField(
                    controller: _priceController,
                    label: _listingType == 'Auction' ? 'Starting Price (₹)' : 'Price (₹)',
                    hint: _listingType == 'Auction' ? 'Minimum bid amount' : 'Fixed price for the item',
                    keyboardType: TextInputType.number,
                  ),
                ),
              if (_listingType == 'Auction') ...[
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Auction Duration',
                  value: '$_auctionDurationHours Hours',
                  items: ['1 Hours', '6 Hours', '24 Hours'],
                  onChanged: (v) {
                    setState(() {
                      _auctionDurationHours = int.parse(v!.split(' ')[0]);
                    });
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.purple.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.gavel_outlined, color: Colors.purple, size: 20),
                      const SizedBox(width: 8),
                      Text('Highest bidder will receive the item', style: TextStyle(color: Colors.purple[700], fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),

              // Submit Button
              Consumer<ProductProvider>(
                builder: (context, product, _) => product.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          onPressed: _submit,
                          text: 'LIST ITEM',
                        ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    String? hint, 
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      validator: (v) => v!.isEmpty ? '$label is required' : null,
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
