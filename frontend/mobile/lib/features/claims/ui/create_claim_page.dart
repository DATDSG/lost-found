import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/models/item.dart';
import '../../../core/models/claim.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_overlay.dart';

class CreateClaimPage extends StatefulWidget {
  final Item item;

  const CreateClaimPage({super.key, required this.item});

  @override
  State<CreateClaimPage> createState() => _CreateClaimPageState();
}

class _CreateClaimPageState extends State<CreateClaimPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final List<File> _evidenceImages = [];
  final List<String> _textEvidence = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.c.surface,
      appBar: AppBar(
        title: Text('Claim Item', style: DT.t.h2),
        backgroundColor: DT.c.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(DT.s.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildItemSummary(),
                  SizedBox(height: DT.s.xl),
                  _buildClaimDescription(),
                  SizedBox(height: DT.s.xl),
                  _buildEvidenceSection(),
                  SizedBox(height: DT.s.xl),
                  _buildContactInfo(),
                  SizedBox(height: DT.s.xl * 2),
                  CustomButton(
                    text: 'Submit Claim',
                    onPressed: _submitClaim,
                    isLoading: _isLoading,
                  ),
                  SizedBox(height: DT.s.xl),
                ],
              ),
            ),
          ),
          if (_isLoading) const LoadingOverlay(message: 'Submitting claim...'),
        ],
      ),
    );
  }

  Widget _buildItemSummary() {
    return Container(
      padding: EdgeInsets.all(DT.s.lg),
      decoration: BoxDecoration(
        color: DT.c.blueTint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DT.c.blueTint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Item to Claim', style: DT.t.h3),
          SizedBox(height: DT.s.md),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: DT.c.blueTint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: widget.item.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.item.images.first.url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.image, color: DT.c.textMuted);
                          },
                        ),
                      )
                    : Icon(Icons.image, color: DT.c.textMuted),
              ),
              SizedBox(width: DT.s.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: DT.t.title.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: DT.s.xs),
                    Text(
                      widget.item.description,
                      style: DT.t.body.copyWith(color: DT.c.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: DT.s.xs),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DT.s.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.item.type == ItemType.lost
                            ? DT.c.danger.withValues(alpha: 0.1)
                            : DT.c.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.item.type == ItemType.lost ? 'LOST' : 'FOUND',
                        style: DT.t.caption.copyWith(
                          color: widget.item.type == ItemType.lost
                              ? DT.c.danger
                              : DT.c.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClaimDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Why is this your item?', style: DT.t.h3),
        SizedBox(height: DT.s.md),
        Text(
          'Provide details that prove this item belongs to you. Be specific about unique features, where you lost it, when, etc.',
          style: DT.t.body.copyWith(color: DT.c.textMuted),
        ),
        SizedBox(height: DT.s.md),
        CustomTextField(
          controller: _descriptionController,
          label: 'Claim Description',
          hint: 'Describe why this item is yours...',
          maxLines: 6,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a description';
            }
            if (value.trim().length < 20) {
              return 'Please provide more details (at least 20 characters)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEvidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Evidence (Optional)', style: DT.t.h3),
        SizedBox(height: DT.s.md),
        Text(
          'Upload photos or provide additional information that proves ownership. This could include receipts, serial numbers, unique markings, etc.',
          style: DT.t.body.copyWith(color: DT.c.textMuted),
        ),
        SizedBox(height: DT.s.md),

        // Photo evidence
        Text('Photo Evidence', style: DT.t.title),
        SizedBox(height: DT.s.sm),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._evidenceImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                return Container(
                  width: 100,
                  height: 100,
                  margin: EdgeInsets.only(right: DT.s.md),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          image,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeEvidenceImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (_evidenceImages.length < 5)
                GestureDetector(
                  onTap: _addEvidenceImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: DT.c.blueTint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: DT.c.blueTint,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          color: DT.c.brand,
                          size: 24,
                        ),
                        SizedBox(height: DT.s.xs),
                        Text(
                          'Add Photo',
                          style: DT.t.caption.copyWith(color: DT.c.brand),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        SizedBox(height: DT.s.lg),

        // Text evidence
        Text('Additional Information', style: DT.t.title),
        SizedBox(height: DT.s.sm),
        ..._textEvidence.asMap().entries.map((entry) {
          final index = entry.key;
          final text = entry.value;
          return Container(
            margin: EdgeInsets.only(bottom: DT.s.sm),
            padding: EdgeInsets.all(DT.s.md),
            decoration: BoxDecoration(
              color: DT.c.blueTint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(child: Text(text, style: DT.t.body)),
                IconButton(
                  onPressed: () => _removeTextEvidence(index),
                  icon: Icon(Icons.delete_outline, color: DT.c.danger),
                ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: _addTextEvidence,
          icon: const Icon(Icons.add),
          label: const Text('Add Information'),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact Information', style: DT.t.h3),
        SizedBox(height: DT.s.md),
        Text(
          'Provide your contact details so the item owner can reach you.',
          style: DT.t.body.copyWith(color: DT.c.textMuted),
        ),
        SizedBox(height: DT.s.md),
        CustomTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: '+94 77 123 4567',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a phone number';
            }
            return null;
          },
        ),
        SizedBox(height: DT.s.lg),
        CustomTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'your.email@example.com',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide an email address';
            }
            if (!RegExp(
              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
            ).hasMatch(value.trim())) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _addEvidenceImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _evidenceImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _removeEvidenceImage(int index) {
    setState(() {
      _evidenceImages.removeAt(index);
    });
  }

  Future<void> _addTextEvidence() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Information'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter additional information...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _textEvidence.add(result);
      });
    }
  }

  void _removeTextEvidence(int index) {
    setState(() {
      _textEvidence.removeAt(index);
    });
  }

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create evidence list
      final evidence = <ClaimEvidence>[];

      // Add image evidence
      for (final image in _evidenceImages) {
        evidence.add(
          ClaimEvidence(
            type: 'image',
            content: image.path, // In real app, upload to server first
            description: 'Photo evidence',
          ),
        );
      }

      // Add text evidence
      for (final text in _textEvidence) {
        evidence.add(
          ClaimEvidence(
            type: 'text',
            content: text,
            description: 'Additional information',
          ),
        );
      }

      // Create claim object (variables used for API submission)
      final claimData = {
        'id': 'claim-${DateTime.now().millisecondsSinceEpoch}',
        'itemId': widget.item.id,
        'claimantId': 'current-user-id', // Get from auth service
        'status': 'pending',
        'description': _descriptionController.text.trim(),
        'evidence': evidence,
        'contactInfo': {
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
        },
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Submit claim data (placeholder for API call)
      debugPrint('Submitting claim: $claimData');

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Claim submitted successfully! You will be notified when it\'s reviewed.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting claim: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
