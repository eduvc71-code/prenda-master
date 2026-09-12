import 'package:flutter/material.dart';

/// Widget de filtro chip según diseño de archivos TXT
class FilterChipGroup extends StatefulWidget {
  final List<String> options;
  final String selectedOption;
  final void Function(String) onSelected;

  const FilterChipGroup({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
  });

  @override
  State<FilterChipGroup> createState() => _FilterChipGroupState();
}

class _FilterChipGroupState extends State<FilterChipGroup> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: widget.options.map((option) {
          final isSelected = option == widget.selectedOption;
          
          return Container(
            height: 34,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? theme.colorScheme.primaryContainer 
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            alignment: AlignmentDirectional.center,
            child: InkWell(
              onTap: () => widget.onSelected(option),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      option,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected 
                            ? theme.colorScheme.onPrimaryContainer 
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
