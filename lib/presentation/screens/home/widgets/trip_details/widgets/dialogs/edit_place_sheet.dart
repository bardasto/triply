import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../../core/constants/color_constants.dart';

/// Bottom sheet for editing place/restaurant with chat-style input.
class EditPlaceSheet extends StatefulWidget {
  final String initialName;
  final int? initialDuration;
  final bool isDark;
  final Function(String name, int? duration) onSave;

  const EditPlaceSheet({
    super.key,
    required this.initialName,
    this.initialDuration,
    required this.isDark,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String initialName,
    int? initialDuration,
    required bool isDark,
    required Function(String name, int? duration) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPlaceSheet(
        initialName: initialName,
        initialDuration: initialDuration,
        isDark: isDark,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditPlaceSheet> createState() => _EditPlaceSheetState();
}

class _EditPlaceSheetState extends State<EditPlaceSheet> {
  late TextEditingController _nameController;
  late TextEditingController _durationController;
  late FocusNode _nameFocus;
  bool _canSave = false;

  Color get _backgroundColor =>
      widget.isDark ? const Color(0xFF1C1C1E) : Colors.white;
  Color get _inputBackground =>
      widget.isDark ? const Color(0xFF2C2C2E) : Colors.grey[100]!;
  Color get _textColor => widget.isDark ? Colors.white : Colors.black;
  Color get _hintColor => widget.isDark ? Colors.white38 : Colors.grey;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _durationController = TextEditingController(
      text: widget.initialDuration?.toString() ?? '',
    );
    _nameFocus = FocusNode();
    _canSave = widget.initialName.isNotEmpty;

    _nameController.addListener(_updateCanSave);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  void _updateCanSave() {
    final canSave = _nameController.text.trim().isNotEmpty;
    if (canSave != _canSave) {
      setState(() => _canSave = canSave);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_canSave) return;

    HapticFeedback.lightImpact();
    final duration = int.tryParse(_durationController.text);
    widget.onSave(_nameController.text.trim(), duration);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            _buildHeader(),
            const SizedBox(height: 16),
            _buildNameInput(),
            const SizedBox(height: 12),
            _buildDurationInput(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 36,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 17,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Edit Place',
            style: TextStyle(
              color: _textColor,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 50), // Balance
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _inputBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                style: TextStyle(color: _textColor, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Place name',
                  hintStyle: TextStyle(color: _hintColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _handleSave(),
              ),
            ),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _inputBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _durationController,
          style: TextStyle(color: _textColor, fontSize: 16),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Duration (minutes) - optional',
            hintStyle: TextStyle(color: _hintColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: Icon(
              CupertinoIcons.clock,
              color: _hintColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _canSave ? _handleSave : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 6),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _canSave ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          CupertinoIcons.arrow_up,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
