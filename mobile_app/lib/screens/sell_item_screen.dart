import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';

class SellItemScreen extends StatefulWidget {
  @override
  _SellItemScreenState createState() => _SellItemScreenState();
}

class _SellItemScreenState extends State<SellItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _rentPriceController = TextEditingController();
  
  String _category = 'Electronics';
  String _condition = 'Good';
  
  bool _allowBuy = true;
  bool _allowRent = false;
  bool _allowDonate = false;
  bool _allowReturn = false;

  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      setState(() {
        _selectedImages.addAll(images.map((x) => File(x.path)).take(4 - _selectedImages.length));
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please add at least 1 image')));
      return;
    }

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    try {
      await Provider.of<ProductProvider>(context, listen: false).uploadProduct(
        name: _nameController.text,
        description: _descController.text,
        category: _category,
        condition: _condition,
        price: double.tryParse(_priceController.text) ?? 0,
        rentPrice: double.tryParse(_rentPriceController.text) ?? 0,
        allowBuy: _allowBuy,
        allowRent: _allowRent,
        allowDonate: _allowDonate,
        allowReturn: _allowReturn,
        sellerId: user.id, // MongoDB ID
        images: _selectedImages,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product Listed for Approval!')));
      Navigator.of(context).pop(); // Go back to home
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sell Item')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product Photos (Max 4)', style: TextStyle(color: Colors.white, fontSize: 16)),
              SizedBox(height: 10),
              Row(
                children: [
                  ..._selectedImages.map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Image.file(f, width: 70, height: 70, fit: BoxFit.cover),
                  )),
                  if (_selectedImages.length < 4)
                    IconButton(
                      icon: Icon(Icons.add_a_photo, color: Colors.purpleAccent, size: 30),
                      onPressed: _pickImages,
                    ),
                ],
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Product Name', filled: true, fillColor: Colors.white10),
                style: TextStyle(color: Colors.white),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: 'Description', filled: true, fillColor: Colors.white10),
                style: TextStyle(color: Colors.white),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _category,
                dropdownColor: Colors.grey[900],
                items: ['Electronics', 'Books', 'Furniture', 'Clothing', 'Other']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: Colors.white))))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
                decoration: InputDecoration(labelText: 'Category', filled: true, fillColor: Colors.white10),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _condition,
                dropdownColor: Colors.grey[900],
                items: ['New', 'Good', 'Fair', 'Poor']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: Colors.white))))
                    .toList(),
                onChanged: (v) => setState(() => _condition = v!),
                decoration: InputDecoration(labelText: 'Condition', filled: true, fillColor: Colors.white10),
              ),
              SizedBox(height: 20),
              CheckboxListTile(
                title: Text('Allow Buy', style: TextStyle(color: Colors.white)),
                value: _allowBuy,
                onChanged: (v) => setState(() => _allowBuy = v!),
                controlAffinity: ListTileControlAffinity.leading,
                checkColor: Colors.black,
                activeColor: Colors.green,
              ),
              if (_allowBuy)
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Selling Price (₹)', filled: true, fillColor: Colors.white10),
                   style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              SizedBox(height: 10),
              CheckboxListTile(
                title: Text('Allow Rent', style: TextStyle(color: Colors.white)),
                value: _allowRent,
                onChanged: (v) => setState(() => _allowRent = v!),
                controlAffinity: ListTileControlAffinity.leading,
                checkColor: Colors.black,
                 activeColor: Colors.orange,
              ),
              if (_allowRent)
                TextFormField(
                  controller: _rentPriceController,
                  decoration: InputDecoration(labelText: 'Rent Price Per Day (₹)', filled: true, fillColor: Colors.white10),
                   style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
               SizedBox(height: 10),
              CheckboxListTile(
                title: Text('Allow Donate', style: TextStyle(color: Colors.white)),
                value: _allowDonate,
                onChanged: (v) => setState(() => _allowDonate = v!),
                controlAffinity: ListTileControlAffinity.leading,
                checkColor: Colors.black,
                activeColor: Colors.blue,
              ),
              SizedBox(height: 30),
               Consumer<ProductProvider>(
                    builder: (context, product, _) => product.isLoading
                        ? Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purpleAccent,
                                padding: EdgeInsets.all(15),
                              ),
                              child: Text('SUBMIT FOR APPROVAL', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                  ),

            ],
          ),
        ),
      ),
    );
  }
}
