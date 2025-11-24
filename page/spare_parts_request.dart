// lib/page/spare_parts_request.dart
import 'package:flutter/material.dart';
import '../class/spare_part_request.dart';
import '../services/spare_part_service.dart';

class SparePartsRequestPage extends StatefulWidget {
  const SparePartsRequestPage({super.key});

  @override
  State<SparePartsRequestPage> createState() => _SparePartsRequestPageState();
}

class _SparePartsRequestPageState extends State<SparePartsRequestPage> {
  final List<SparePart> _requestedParts = [];
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  final List<String> _sparePartsList = [
    'Brake Pads',
    'Brake Discs (Rotors)',
    'Brake Shoes',
    'Brake Calipers',
    'Brake Fluid',
    'Battery (12V / Car Battery)',
    'Alternator',
    'Starter Motor',
    'Spark Plugs',
    'Ignition Coils',
    'Fuses',
    'Engine Oil (5W-30, 10W-40, etc.)',
    'Oil Filter',
    'Air Filter',
    'Fuel Filter',
    'Timing Belt',
    'Drive Belt',
    'Radiator Hose',
    'Shock Absorbers',
    'Struts',
    'Tie Rod Ends',
    'Ball Joints',
    'Control Arms',
    'Clutch Plate',
    'Clutch Disc',
    'Gear Oil',
    'CV Joints',
    'Differential Oil',
    'Tire (various sizes)',
    'Wheel Bearings',
    'Valve Stems',
    'Lug Nuts',
    'Radiator',
    'Radiator Cap',
    'Water Pump',
    'Thermostat',
    'Coolant',
    'Muffler',
    'Catalytic Converter',
    'Exhaust Pipe',
    'Oxygen Sensor',
    'Headlight Bulbs',
    'Tail Light Bulbs',
    'Wiper Blades',
    'Windshield Washer Fluid',
  ];

  String? _selectedPartName;
  int _quantity = 1;
  final TextEditingController _partNotesController = TextEditingController();

  // NEW: key to read selection/typed text from the dropdown
  final GlobalKey<_SparePartDropdownState> _dropdownKey =
  GlobalKey<_SparePartDropdownState>();

  @override
  void dispose() {
    _notesController.dispose();
    _partNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Spare Parts'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddPartSection(),
            const SizedBox(height: 24),
            if (_requestedParts.isNotEmpty) ...[
              _buildPartsList(),
              const SizedBox(height: 24),
              _buildNotesSection(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddPartSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Spare Part',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPartSelector(),
            const SizedBox(height: 16),
            _buildQuantitySelector(),
            const SizedBox(height: 16),
            _buildNotesField(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addPart,
                icon: const Icon(Icons.add),
                label: const Text('Add Part'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Spare Part',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _SparePartDropdown(
          key: _dropdownKey,
          spareParts: _sparePartsList,
          onPartSelected: (partName) {
            setState(() {
              _selectedPartName = partName;
            });
          },
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: _quantity > 1 ? _decreaseQuantity : null,
              icon: const Icon(Icons.remove),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _quantity.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: _increaseQuantity,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _partNotesController,
          decoration: InputDecoration(
            hintText: 'Add notes for this part...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPartsList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'List of Added Parts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_requestedParts.length} part${_requestedParts.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._requestedParts.asMap().entries.map((entry) {
              final index = entry.key;
              final part = entry.value;
              return _buildPartItem(part, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPartItem(SparePart part, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.partName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (part.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    part.notes,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Qty: ${part.quantity}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue[800],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _removePart(index),
            icon: const Icon(Icons.delete, color: Colors.red),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Add any additional notes for this request...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : _cancelRequest,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              'Submit Request',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _addPart() {
    // Use selected name, or first match, or typed text from the dropdown
    String? name = _selectedPartName ??
        _dropdownKey.currentState?.selectedOrFirstMatch();

    if (name == null || name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a spare part'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _requestedParts.add(
        SparePart(
          partName: name.trim(),
          quantity: _quantity,
          notes: _partNotesController.text.trim(),
        ),
      );
      // reset inputs
      _selectedPartName = null;
      _quantity = 1;
      _partNotesController.clear();
      _dropdownKey.currentState?.clearSelection();
    });
  }

  void _removePart(int index) {
    setState(() => _requestedParts.removeAt(index));
  }

  void _increaseQuantity() => setState(() => _quantity++);
  void _decreaseQuantity() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  void _cancelRequest() => Navigator.of(context).pop();

  Future<void> _submitRequest() async {
    if (_requestedParts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one spare part'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await SparePartService.createSparePartRequest(
        _requestedParts,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spare parts request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _SparePartDropdown extends StatefulWidget {
  final List<String> spareParts;
  final ValueChanged<String> onPartSelected;

  const _SparePartDropdown({
    super.key,
    required this.spareParts,
    required this.onPartSelected,
  });

  @override
  State<_SparePartDropdown> createState() => _SparePartDropdownState();
}

class _SparePartDropdownState extends State<_SparePartDropdown> {
  String? _selectedPart;
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredParts = [];

  @override
  void initState() {
    super.initState();
    _filteredParts = widget.spareParts;
    _searchController.addListener(_filterParts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterParts() {
    setState(() {
      _filteredParts = widget.spareParts
          .where((p) =>
          p.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  // Expose a safe selection for the parent:
  // selected > first filtered > raw typed text
  String? selectedOrFirstMatch() {
    if (_selectedPart != null && _selectedPart!.trim().isNotEmpty) {
      return _selectedPart;
    }
    if (_filteredParts.isNotEmpty) {
      return _filteredParts.first;
    }
    final raw = _searchController.text.trim();
    return raw.isEmpty ? null : raw;
  }

  // Allow parent to clear selection after adding
  void clearSelection() {
    setState(() {
      _selectedPart = null;
      _searchController.clear();
      _filteredParts = widget.spareParts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search spare parts...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onSubmitted: (_) {
            final s = selectedOrFirstMatch();
            if (s != null) {
              _selectedPart = s;
              widget.onPartSelected(s);
            }
          },
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: _filteredParts.length,
            itemBuilder: (context, index) {
              final part = _filteredParts[index];
              final isSelected = _selectedPart == part;

              return ListTile(
                title: Text(part),
                selected: isSelected,
                selectedTileColor: Colors.blue[50],
                onTap: () {
                  setState(() => _selectedPart = part);
                  widget.onPartSelected(part);
                },
                trailing:
                isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
