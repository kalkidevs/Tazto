import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RoleToggle extends StatefulWidget {
  final bool isCustomer;
  final ValueChanged<bool> onChanged;

  const RoleToggle({
    super.key,
    required this.isCustomer,
    required this.onChanged,
  });

  @override
  State<RoleToggle> createState() => _RoleToggleState();
}

class _RoleToggleState extends State<RoleToggle> {
  bool _isDragging = false;
  double _dragX = 0;

  void _commit(bool isCustomer) {
    HapticFeedback.selectionClick();
    widget.onChanged(isCustomer);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final totalWidth = constraints.maxWidth;
        final padding = 4.0;
        final thumbWidth = (totalWidth / 2) - (padding);
        final alignTarget = widget.isCustomer ? Alignment.centerLeft : Alignment.centerRight;

        return RepaintBoundary(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              children: [
                // Sliding thumb
                AnimatedAlign(
                  alignment: _isDragging ? Alignment.centerLeft : alignTarget,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: Transform.translate(
                    offset: Offset(_isDragging ? _dragX.clamp(0, totalWidth - thumbWidth - padding * 2) : 0, 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      width: thumbWidth,
                      margin: EdgeInsets.all(padding),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Text layer + interactions
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _commit(true),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: widget.isCustomer ? Colors.white : Colors.black87,
                            ),
                            child: const Text("Customer"),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _commit(false),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: !widget.isCustomer ? Colors.white : Colors.black87,
                            ),
                            child: const Text("Seller"),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Drag handle
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) {
                    setState(() {
                      _isDragging = true;
                      _dragX = widget.isCustomer ? 0 : (totalWidth / 2) - padding;
                    });
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragX += details.delta.dx;
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    final threshold = totalWidth / 4;
                    final endAsCustomer = _dragX < threshold;
                    setState(() {
                      _isDragging = false;
                      _dragX = 0;
                    });
                    _commit(endAsCustomer);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
