import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// add data tempat
class AddJobPage extends StatefulWidget {
  const AddJobPage({super.key});

  @override
  State<AddJobPage> createState() => _AddJobPageState();
}

class _AddJobPageState extends State<AddJobPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _jobId = TextEditingController();
  final _customerId = TextEditingController();
  final _assignedMechanic = TextEditingController();
  final _jobDescription = TextEditingController();
  final _vehicle = TextEditingController();
  final _serviceHistory = TextEditingController();

  String _category = 'Oil Change';
  String _status = 'Pending';
  bool _saving = false;

  @override
  void dispose() {
    _jobId.dispose();
    _customerId.dispose();
    _assignedMechanic.dispose();
    _jobDescription.dispose();
    _vehicle.dispose();
    _serviceHistory.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final history = _serviceHistory.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final data = {
      'jobId': _jobId.text.trim(),
      'customerId': _customerId.text.trim(),
      'assignedMechanic': _assignedMechanic.text.trim(),
      'category': _category,
      'jobDescription': _jobDescription.text.trim(),
      'status': _status,
      'vehicle': _vehicle.text.trim(),
      'serviceHistory': history,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      final docId = _jobId.text.trim().isEmpty ? null : _jobId.text.trim();
      final col = FirebaseFirestore.instance.collection('jobs');

      if (docId == null) {
        await col.add(data);
      } else {
        await col.doc(docId).set(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job saved')),
        );
        Navigator.pop(context); // go back after save
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: const OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Job')),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _saving,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _jobId,
                    decoration: _dec('Job ID', hint: 'e.g. J001 (optional if auto-id)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customerId,
                    decoration: _dec('Customer ID', hint: 'e.g. C001'),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Customer ID required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _assignedMechanic,
                    decoration: _dec('Assigned Mechanic', hint: 'e.g. M001'),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Assigned mechanic required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Category dropdown
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: _dec('Category'),
                    items: const [
                      DropdownMenuItem(value: 'Oil Change', child: Text('Oil Change')),
                      DropdownMenuItem(value: 'Brake Service', child: Text('Brake Service')),
                      DropdownMenuItem(value: 'Tire Rotation', child: Text('Tire Rotation')),
                      DropdownMenuItem(value: 'General Inspection', child: Text('General Inspection')),
                      DropdownMenuItem(value: 'Full Maintenance', child: Text('Full Maintenance')),
                      DropdownMenuItem(value: 'Car Painting', child: Text('Car Painting')),
                      DropdownMenuItem(value: 'Car Repair', child: Text('Car Repair')),
                    ],
                    onChanged: (v) => setState(() => _category = v ?? _category),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _jobDescription,
                    maxLines: 3,
                    decoration: _dec('Job Description',
                        hint: 'Engine oil change and filter check'),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Description required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Status dropdown
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: _dec('Status'),
                    items: const [
                      DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? _status),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _vehicle,
                    decoration: _dec('Vehicle', hint: 'e.g. Toyota Vios 1.5G'),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Vehicle required' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _serviceHistory,
                    decoration: _dec('Service History',
                        hint: 'Comma separated: Checked oil level, Replaced oil filter'),
                  ),
                  const SizedBox(height: 20),

                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Saving...' : 'Save Job'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
