import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SingleSelectDropdown<T> extends StatefulWidget {
  final String label;
  final bool isRequired;
  final List<T> options;
  final String? selectedId;
  final Function(String?) onSelectionChanged;
  final String Function(T) getDisplayText;
  final String? Function(T)? getSubText;
  final String Function(T) getId;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool enabled;

  const SingleSelectDropdown({
    super.key,
    required this.label,
    this.isRequired = false,
    required this.options,
    required this.selectedId,
    required this.onSelectionChanged,
    required this.getDisplayText,
    this.getSubText,
    required this.getId,
    this.hintText,
    this.validator,
    this.enabled = true,
  });

  @override
  State<SingleSelectDropdown<T>> createState() =>
      _SingleSelectDropdownState<T>();
}

class _SingleSelectDropdownState<T> extends State<SingleSelectDropdown<T>> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _isDropdownOpen = false;
  List<T> _filteredOptions = [];
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _searchController.addListener(_filterOptions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterOptions() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions = widget.options.where((option) {
          final displayText = widget.getDisplayText(option).toLowerCase();
          final subText = widget.getSubText?.call(option)?.toLowerCase() ?? '';
          return displayText.contains(query) || subText.contains(query);
        }).toList();
      }
    });
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;

    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
      if (!_isDropdownOpen) {
        _searchController.clear();
        _focusNode.unfocus();
        if (widget.validator != null) {
          _errorText = widget.validator!(widget.selectedId);
        }
      } else {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _isDropdownOpen) {
            _focusNode.requestFocus();
          }
        });
      }
    });
  }

  void _selectOption(String id) {
    widget.onSelectionChanged(id);
    _searchController.clear();
    _focusNode.unfocus();
    setState(() {
      _isDropdownOpen = false;
      if (widget.validator != null) {
        _errorText = widget.validator!(id);
      }
    });
  }

  void _clearSelection() {
    widget.onSelectionChanged(null);
    setState(() {
      if (widget.validator != null) {
        _errorText = widget.validator!(null);
      }
    });
  }

  Widget _buildSelectedOption(T option) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.getDisplayText(option),
          style: const TextStyle(fontSize: 16, color: AppTheme.foreground),
        ),
        if (widget.getSubText != null)
          Builder(
            builder: (context) {
              final subText = widget.getSubText!(option);
              if (subText != null && subText.isNotEmpty) {
                return Text(
                  subText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedForeground,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    T? selectedOption;
    if (widget.selectedId != null && widget.options.isNotEmpty) {
      try {
        selectedOption = widget.options.firstWhere(
          (option) => widget.getId(option) == widget.selectedId,
        );
      } catch (e) {
        selectedOption = null;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.foreground,
              ),
            ),
            if (widget.isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: widget.enabled
                ? AppTheme.inputBackground
                : AppTheme.inputBackground,
            border: Border.all(
              color: _errorText != null
                  ? AppTheme.destructive
                  : (_isDropdownOpen ? AppTheme.ring : AppTheme.border),
              width: _isDropdownOpen ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Input field
              InkWell(
                onTap: widget.enabled ? _toggleDropdown : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: selectedOption == null
                            ? Text(
                                widget.hintText ??
                                    'Select ${widget.label.toLowerCase()}',
                                style: const TextStyle(
                                  color: AppTheme.mutedForeground,
                                  fontSize: 16,
                                ),
                              )
                            : _buildSelectedOption(selectedOption),
                      ),
                      if (selectedOption != null && widget.enabled)
                        GestureDetector(
                          onTap: _clearSelection,
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        _isDropdownOpen
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTheme.mutedForeground,
                      ),
                    ],
                  ),
                ),
              ),
              // Dropdown list
              if (_isDropdownOpen)
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search field
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            fillColor: AppTheme.inputBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: AppTheme.border,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      // Options list
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: _filteredOptions.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No results found',
                                  style: TextStyle(
                                    color: AppTheme.mutedForeground,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _filteredOptions.length,
                                itemBuilder: (context, index) {
                                  final option = _filteredOptions[index];
                                  final id = widget.getId(option);
                                  final isSelected = widget.selectedId == id;
                                  final displayText = widget.getDisplayText(
                                    option,
                                  );
                                  final subText = widget.getSubText?.call(
                                    option,
                                  );

                                  return InkWell(
                                    onTap: () {
                                      _selectOption(id);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      color: isSelected
                                          ? AppTheme.primary.withOpacity(0.1)
                                          : null,
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_unchecked,
                                            size: 20,
                                            color: isSelected
                                                ? AppTheme.primary
                                                : AppTheme.mutedForeground,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  displayText,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w500
                                                        : FontWeight.normal,
                                                    color: isSelected
                                                        ? AppTheme.primary
                                                        : AppTheme.foreground,
                                                  ),
                                                ),
                                                if (subText != null &&
                                                    subText.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    subText,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: AppTheme
                                                          .mutedForeground,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              _errorText!,
              style: const TextStyle(color: AppTheme.destructive, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
