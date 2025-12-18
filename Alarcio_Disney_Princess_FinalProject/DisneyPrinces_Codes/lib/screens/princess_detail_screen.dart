import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:disney_princess_app/models/princess.dart';

class PrincessDetailScreen extends StatefulWidget {
  final Princess princess;

  const PrincessDetailScreen({super.key, required this.princess});

  @override
  State<PrincessDetailScreen> createState() => _PrincessDetailScreenState();
}

class _PrincessDetailScreenState extends State<PrincessDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _avatarController;
  late Animation<double> _avatarPulseAnimation;
  late AnimationController _titleController;
  late Animation<double> _titleOpacityAnimation;
  late Animation<Offset> _titleSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Avatar pulse animation
    _avatarController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _avatarPulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _avatarController,
      curve: Curves.easeInOut,
    ));
    
    // Title animations
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _titleOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeIn,
    ));
    
    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _titleController.forward();
  }

  @override
  void dispose() {
    _avatarController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8E6EC8), // New purple color
                Color(0xFFE3A7C7), // New pink color
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // AppBar content
              AppBar(
                title: Text(
                  widget.princess.name,
                  style: GoogleFonts.greatVibes(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 3,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFFF1D6E6), // Center color
              Color(0xFFFFFFFF), // Outer color
            ],
            center: Alignment(0.0, -0.5), // Position of the radial center
            radius: 1.2, // Radius of the gradient
          ),
        ),
        child: Stack(
          children: [
            // Decorative sparkle stars for Disney feels
            Positioned(
              top: 100,
              right: 30,
              child: Icon(
                Icons.star,
                color: const Color(0xFF8E6CB0).withOpacity(0.2),
                size: 15,
              ),
            ),
            Positioned(
              top: 180,
              left: 40,
              child: Icon(
                Icons.star,
                color: const Color(0xFFEAA7C4).withOpacity(0.3),
                size: 12,
              ),
            ),
            Positioned(
              bottom: 200,
              right: 50,
              child: Icon(
                Icons.star,
                color: const Color(0xFF8E6CB0).withOpacity(0.25),
                size: 10,
              ),
            ),
            Positioned(
              bottom: 120,
              left: 60,
              child: Icon(
                Icons.star,
                color: const Color(0xFFEAA7C4).withOpacity(0.2),
                size: 14,
              ),
            ),
            Positioned(
              top: -150,
              right: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEAA7C4).withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -200,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4DB6AC).withOpacity(0.1),
                ),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Class Photo Section with enhanced styling and pulse animation
                  Hero(
                    tag: 'princess_${widget.princess.id}',
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.45,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8E6CB0), // Disney purple
                            Color(0xFFEAA7C4), // Disney pink
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Enhanced background pattern
                          CustomPaint(
                            size: Size(double.infinity, MediaQuery.of(context).size.height * 0.45),
                            painter: _PrincessDetailPainter(),
                          ),
                          // Profile Image with double ring and glow effect (royal badge) with pulse animation
                          ScaleTransition(
                            scale: _avatarPulseAnimation,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8E6CB0), // Disney purple
                                    Color(0xFFEAA7C4), // Disney pink
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8E6CB0).withOpacity(0.5),
                                    blurRadius: 25,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFF1D6E6), // Changed to #F1D6E6
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: AssetImage(widget.princess.imageUrl),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Class Information Section with enhanced styling
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 25,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name and Star aligned properly with circular star and glow - animated
                          FadeTransition(
                            opacity: _titleOpacityAnimation,
                            child: SlideTransition(
                              position: _titleSlideAnimation,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.princess.name,
                                    style: GoogleFonts.greatVibes(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF8E6CB0), // Disney purple
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Class ID with gradient chip and crown icon
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFEAA7C4),
                                  Color(0xFF8E6CB0),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8E6CB0).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.coronavirus, // Crown icon
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Class ID: ${widget.princess.id}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Class Description in soft card with accent bar
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF8F4FF),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Accent bar
                                  Container(
                                    height: 4,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF8E6CB0),
                                          Color(0xFFEAA7C4),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  // Description header
                                  const Text(
                                    'Class Description',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8E6CB0), // Disney purple
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  // Description text
                                  Text(
                                    widget.princess.description,
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.6,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }
}

class _PrincessDetailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8E6CB0).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw decorative circles
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.4,
      paint,
    );

    paint.color = const Color(0xFFEAA7C4).withOpacity(0.1);
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.3),
      size.width * 0.1,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.7),
      size.width * 0.08,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}