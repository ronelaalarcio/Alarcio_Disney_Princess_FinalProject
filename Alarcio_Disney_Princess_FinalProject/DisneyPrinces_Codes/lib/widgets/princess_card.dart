import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:disney_princess_app/services/analytics_service.dart';
import '../models/princess.dart';

class PrincessCard extends StatefulWidget {
  final Princess princess;
  final VoidCallback onTap;

  const PrincessCard({
    super.key,
    required this.princess,
    required this.onTap,
  });

  @override
  State<PrincessCard> createState() => _PrincessCardState();
}

class _PrincessCardState extends State<PrincessCard>
    with TickerProviderStateMixin {  // Changed from SingleTickerProviderStateMixin
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _glowAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    // Pulse animation for the avatar
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 6, // Increased from 4 to 6 for more subtle lift
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF8F4FF),
                  Color(0xFFFCF8FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Princess Icon with gradient ring and glow effect with pulse animation
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF8E6CB0),
                                Color(0xFFEAA7C4),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8E6CB0).withOpacity(0.3 * _glowAnimation.value), // Animated glow
                                blurRadius: 12 * _glowAnimation.value, // Animated blur
                                spreadRadius: 1 * _glowAnimation.value, // Animated spread
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFF1D6E6), // Changed from Colors.white to #F1D6E6
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  widget.princess.imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Princess Name - using darker purple color
                  Text(
                    widget.princess.name,
                    style: GoogleFonts.greatVibes(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4B0082), // Darker purple
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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