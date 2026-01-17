import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MultiSelectDropdown<T> extends StatefulWidget {
  final String label;
  final bool isRequired;
  final List<T> options;
  final List<String> selectedIds;
  final Function(List<String>) onSelectionChanged;
  final String Function(T) getDisplayText;
  final String? Function(T)? getSubText;
  final String Function(T) getId;
  final String? hintText;

  const MultiSelectDropdown({
    super.key,
    required this.label,
    this.isRequired = false,
    required this.options,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.getDisplayText,
    this.getSubText,
    required this.getId,
    this.hintText,
  });

  @override
  State<MultiSelectDropdown<T>> createState() => _MultiSelectDropdownState<T>();
}

class _MultiSelectDropdownState<T> extends State<MultiSelectDropdown<T>> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _isDropdownOpen = false;
  List<T> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _searchController.addListener(_filterOptions);
    _focusNode.addListener(() {
      // Only close dropdown when focus is lost, not when it's gained
      if (!_focusNode.hasFocus && _isDropdownOpen) {
        // Delay closing to allow for selection clicks
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_focusNode.hasFocus) {
            setState(() {
              _isDropdownOpen = false;
            });
          }
        });
      }
    });
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
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
      if (!_isDropdownOpen) {
        _searchController.clear();
        _focusNode.unfocus();
      } else {
        // Request focus after a small delay to ensure dropdown is rendered
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _isDropdownOpen) {
            _focusNode.requestFocus();
          }
        });
      }
    });
  }

  void _toggleSelection(String id) {
    final currentSelection = List<String>.from(widget.selectedIds);
    if (currentSelection.contains(id)) {
      currentSelection.remove(id);
    } else {
      currentSelection.add(id);
    }
    widget.onSelectionChanged(currentSelection);
    // Keep dropdown open after selection
    setState(() {});
  }

  void _selectAll() {
    final allIds = widget.options
        .map((option) => widget.getId(option))
        .toList();
    widget.onSelectionChanged(allIds);
  }

  void _clearAll() {
    widget.onSelectionChanged([]);
  }

  void _removeSelection(String id) {
    final currentSelection = List<String>.from(widget.selectedIds);
    currentSelection.remove(id);
    widget.onSelectionChanged(currentSelection);
  }

  @override
  Widget build(BuildContext context) {
    final selectedOptions = widget.options
        .where((option) => widget.selectedIds.contains(widget.getId(option)))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                style: TextStyle(color: Color.fromARGB(255, 114, 112, 113)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.inputBackground,
            border: Border.all(
              color: _isDropdownOpen ? AppTheme.ring : AppTheme.border,
              width: _isDropdownOpen ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              // Input field with selected chips
              InkWell(
                onTap: _toggleDropdown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: selectedOptions.isEmpty
                            ? Text(
                                widget.hintText ??
                                    'Select ${widget.label.toLowerCase()}',
                                style: const TextStyle(
                                  color: AppTheme.mutedForeground,
                                  fontSize: 16,
                                ),
                              )
                            : Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: selectedOptions.map((option) {
                                  final id = widget.getId(option);
                                  final displayText = widget.getDisplayText(
                                    option,
                                  );
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppTheme.primary.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          displayText,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.foreground,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () {
                                            _removeSelection(id);
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: AppTheme.foreground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      if (selectedOptions.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _clearAll();
                          },
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
                GestureDetector(
                  onTap: () {}, // Prevent clicks from closing dropdown
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppTheme.border)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search field
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () {}, // Prevent tap from closing
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              onTap: () {}, // Prevent tap from closing
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
                        ),
                        // Options list
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount:
                                _filteredOptions.length +
                                1, // +1 for "All" option
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                // "All" option
                                final allSelected =
                                    widget.selectedIds.length ==
                                    widget.options.length;
                                return InkWell(
                                  onTap: () {
                                    if (allSelected) {
                                      _clearAll();
                                    } else {
                                      _selectAll();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    color: allSelected
                                        ? AppTheme.primary.withOpacity(0.1)
                                        : null,
                                    child: Row(
                                      children: [
                                        Icon(
                                          allSelected
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          size: 20,
                                          color: allSelected
                                              ? AppTheme.primary
                                              : AppTheme.mutedForeground,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'All',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: allSelected
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                            color: allSelected
                                                ? AppTheme.primary
                                                : AppTheme.foreground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final option = _filteredOptions[index - 1];
                              final id = widget.getId(option);
                              final isSelected = widget.selectedIds.contains(
                                id,
                              );
                              final displayText = widget.getDisplayText(option);
                              final subText = widget.getSubText?.call(option);

                              return InkWell(
                                onTap: () {
                                  _toggleSelection(id);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  color: isSelected
                                      ? AppTheme.primary.withOpacity(0.1)
                                      : null,
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.check_box
                                            : Icons.check_box_outline_blank,
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
                                          children: [
                                            Text(
                                              displayText,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: isSelected
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                                color: isSelected
                                                    ? AppTheme.primary
                                                    : AppTheme.foreground,
                                              ),
                                            ),
                                            if (subText != null &&
                                                subText.isNotEmpty)
                                              Text(
                                                subText,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color:
                                                      AppTheme.mutedForeground,
                                                ),
                                              ),
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
                ),
            ],
          ),
        ),
      ],
    );
  }
}
