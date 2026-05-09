import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'catalogue_part_model.dart';
import 'part_popup_dialog.dart';

/// A clickable hotspot placed over the image to select a specific part.
class PartHotspotWidget extends StatefulWidget {
  final CataloguePart part;

  const PartHotspotWidget({super.key, required this.part});

  @override
  State<PartHotspotWidget> createState() => _PartHotspotWidgetState();
}

class _PartHotspotWidgetState extends State<PartHotspotWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => PartPopupDialog(part: widget.part),
        );
      },
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.accentYellow.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkGreen.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.add_circle_outline,
              color: AppColors.darkGreen,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

