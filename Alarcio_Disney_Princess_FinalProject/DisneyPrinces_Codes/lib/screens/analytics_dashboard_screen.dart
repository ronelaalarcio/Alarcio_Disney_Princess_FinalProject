import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:disney_princess_app/services/firebase_service.dart';
import 'package:disney_princess_app/services/analytics_service.dart';
import 'package:google_fonts/google_fonts.dart';

// Import the princesses list and required types
import '../models/princess.dart' show princesses, Princess;
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, int> _scanCounts = {};
  List<Map<String, dynamic>> _recentScans = [];
  int _totalScans = 0;
  int _lowConfidenceCount = 0;
  String _mostScannedPrincess = 'None';
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('AnalyticsDashboard');
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch scan counts
      final scanCounts = await _firebaseService.getPrincessScanCounts();
      
      // Fetch recent scans for detailed analysis
      final recentScans = await _fetchRecentScans();
      
      // Calculate analytics metrics
      final totalScans = scanCounts.values.fold(0, (sum, count) => sum + count);
      final lowConfidenceCount = await _calculateLowConfidenceCount();
      final mostScannedPrincess = _getMostScannedPrincess(scanCounts);
      
      setState(() {
        _scanCounts = scanCounts;
        _recentScans = recentScans;
        _totalScans = totalScans;
        _lowConfidenceCount = lowConfidenceCount;
        _mostScannedPrincess = mostScannedPrincess;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching analytics data: $e');
      setState(() {
        _errorMessage = 'Failed to load analytics data. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecentScans() async {
    try {
      final querySnapshot = await _firebaseService.firestore.collection('classifications')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();
      
      final recentScans = <Map<String, dynamic>>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final classificationData = data['data'];
          if (classificationData != null) {
            recentScans.add({
              'princessName': classificationData['princessName'] ?? 'Unknown',
              'confidence': classificationData['confidence'] ?? '0.00',
              'timestamp': data['timestamp'],
              'id': doc.id,
            });
          }
        } catch (docError) {
          print('Error processing recent scan document ${doc.id}: $docError');
        }
      }
      
      return recentScans;
    } catch (e) {
      print('Error fetching recent scans: $e');
      return [];
    }
  }

  Future<int> _calculateLowConfidenceCount() async {
    try {
      // Query for classifications with low confidence (0.0 or very low)
      // Include both zero confidence (black images/invalid scans) and below 10% confidence
      final zeroConfidenceQuery = await _firebaseService.firestore.collection('classifications')
        .where('data.confidence', isEqualTo: 0.0)
        .get();
      
      final lowConfidenceQuery = await _firebaseService.firestore.collection('classifications')
        .where('data.confidence', isGreaterThan: 0.0)
        .where('data.confidence', isLessThan: 10.0)
        .get();
      
      return zeroConfidenceQuery.docs.length + lowConfidenceQuery.docs.length;
    } catch (e) {
      print('Error calculating low confidence count: $e');
      return 0;
    }
  }

  String _getMostScannedPrincess(Map<String, int> scanCounts) {
    if (scanCounts.isEmpty) return 'None';
    
    String mostScanned = '';
    int maxCount = 0;
    
    scanCounts.forEach((princess, count) {
      if (count > maxCount) {
        maxCount = count;
        mostScanned = princess;
      }
    });
    
    return mostScanned.isEmpty ? 'None' : mostScanned;
  }

  double _getPrincessPercentage(String princessName, Map<String, int> scanCounts) {
    final totalScans = scanCounts.values.fold(0, (sum, count) => sum + count);
    if (totalScans == 0) return 0.0;
    
    final princessScans = scanCounts[princessName] ?? 0;
    return (princessScans / totalScans) * 100;
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
                  'Analytics Dashboard',
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
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              // Subtle sparkle overlay
              Positioned(
                top: 8,
                right: 80,
                child: Icon(
                  Icons.star,
                  color: Colors.white.withOpacity(0.3),
                  size: 12,
                ),
              ),
              Positioned(
                top: 12,
                left: 100,
                child: Icon(
                  Icons.star,
                  color: Colors.white.withOpacity(0.2),
                  size: 8,
                ),
              ),
              Positioned(
                bottom: 10,
                right: 120,
                child: Icon(
                  Icons.star,
                  color: Colors.white.withOpacity(0.25),
                  size: 10,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Princess Scan Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E6CB0),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Comprehensive statistics and insights',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              
              if (_isLoading) ...[
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E6CB0)),
                      ),
                      SizedBox(height: 20),
                      Text('Loading analytics data...'),
                    ],
                  ),
                ),
              ] else if (_errorMessage.isNotEmpty) ...[
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchAnalyticsData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E6CB0),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _AnalyticsSummary(
                  totalScans: _totalScans,
                  mostScannedPrincess: _mostScannedPrincess,
                  lowConfidenceCount: _lowConfidenceCount,
                ),
                const SizedBox(height: 30),
                _AnalyticsContent(
                  scanCounts: _scanCounts,
                  recentScans: _recentScans,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

// Summary cards widget
class _AnalyticsSummary extends StatelessWidget {
  final int totalScans;
  final String mostScannedPrincess;
  final int lowConfidenceCount;

  const _AnalyticsSummary({
    required this.totalScans,
    required this.mostScannedPrincess,
    required this.lowConfidenceCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary Cards Row
        Row(
          children: [
            // Total Scans Card
            Expanded(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bar_chart,
                        color: Color(0xFF8E6CB0),
                        size: 16,
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$totalScans',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8E6CB0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Most Scanned Princess Card
            Expanded(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFF8E6CB0),
                        size: 16,
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Most Scanned',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          mostScannedPrincess,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8E6CB0),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Low Confidence Card
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Row(
              children: [
                const Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Low Confidence/Black Images',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$lowConfidenceCount scans',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      const Text(
                        '(Zero confidence = Black/Invalid images)',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Main analytics content widget
class _AnalyticsContent extends StatelessWidget {
  final Map<String, int> scanCounts;
  final List<Map<String, dynamic>> recentScans;

  const _AnalyticsContent({
    required this.scanCounts,
    required this.recentScans,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bar Chart Section - Scan Count per Princess
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan Counts (Bar Chart)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E6CB0),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      barGroups: _getBarGroups(scanCounts),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < princesses.length) {
                                // Truncate long names for better display
                                String name = princesses[index].name;
                                if (name.length > 8) {
                                  name = '${name.substring(0, 6)}..';
                                }
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  angle: -0.6, // rotate ~35 degrees
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                            reservedSize: 40,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: true),
                      maxY: scanCounts.values.isEmpty 
                          ? 1 
                          : (scanCounts.values.reduce((a, b) => a > b ? a : b) * 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Pie Chart Section - Percentage Distribution
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan Distribution (Pie Chart)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E6CB0),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: _getPieSections(scanCounts),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Detailed Table - (Princess | Scans | %)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detailed Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E6CB0),
                  ),
                ),
                const SizedBox(height: 15),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Princess')),
                    DataColumn(label: Text('Scans')),
                    DataColumn(label: Text('Percentage')),
                  ],
                  rows: _getPrincessDataRows(scanCounts),
                  headingRowColor: MaterialStateProperty.all(const Color(0xFF8E6CB0).withOpacity(0.1)),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Recent Scans Section - Last 10
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Scans (Last 10)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E6CB0),
                  ),
                ),
                const SizedBox(height: 15),
                if (recentScans.isEmpty) ...[
                  const Center(
                    child: Text(
                      'No recent scans available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ] else ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentScans.length,
                    itemBuilder: (context, index) {
                      final scan = recentScans[index];
                      return _RecentScanItem(scan: scan);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  List<BarChartGroupData> _getBarGroups(Map<String, int> scanCounts) {
    final barGroups = <BarChartGroupData>[];
    
    for (int i = 0; i < princesses.length; i++) {
      final princess = princesses[i];
      final count = scanCounts[princess.name] ?? 0;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: const Color(0xFF8E6CB0),
              width: 20,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }
    
    return barGroups;
  }
  
  List<PieChartSectionData> _getPieSections(Map<String, int> scanCounts) {
    final sections = <PieChartSectionData>[];
    final totalScans = scanCounts.values.fold(0, (sum, count) => sum + count);
    
    if (totalScans == 0) {
      // If no scans, show a single section
      sections.add(
        PieChartSectionData(
          value: 1,
          title: 'No Data',
          color: Colors.grey,
          radius: 50,
        ),
      );
      return sections;
    }
    
    // Colors for different princesses
    final colors = [
      const Color(0xFF8E6CB0), // Purple
      const Color(0xFFEAA7C4), // Pink
      const Color(0xFF4DB6AC), // Teal
      const Color(0xFFFFB74D), // Orange
      const Color(0xFFBA68C8), // Light Purple
      const Color(0xFF81C784), // Green
      const Color(0xFF64B5F6), // Blue
      const Color(0xFFFF8A65), // Deep Orange
      const Color(0xFFAED581), // Light Green
      const Color(0xFF90A4AE), // Blue Grey
    ];
    
    for (int i = 0; i < princesses.length; i++) {
      final princess = princesses[i];
      final count = scanCounts[princess.name] ?? 0;
      
      if (count > 0) {
        final percentage = (count / totalScans) * 100;
        sections.add(
          PieChartSectionData(
            value: count.toDouble(),
            title: '${percentage.toStringAsFixed(1)}%',
            color: colors[i % colors.length],
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }
    
    return sections;
  }
  
  List<DataRow> _getPrincessDataRows(Map<String, int> scanCounts) {
    final rows = <DataRow>[];
    final totalScans = scanCounts.values.fold(0, (sum, count) => sum + count);
    
    // Sort princesses by scan count (descending)
    final sortedPrincesses = List<Princess>.from(princesses);
    sortedPrincesses.sort((a, b) {
      final countA = scanCounts[(a as Princess).name] ?? 0;
      final countB = scanCounts[(b as Princess).name] ?? 0;
      return countB.compareTo(countA);
    });
    
    for (final princess in sortedPrincesses) {
      final count = scanCounts[princess.name] ?? 0;
      final percentage = totalScans > 0 ? (count / totalScans) * 100 : 0;
      
      rows.add(
        DataRow(
          cells: [
            DataCell(Text(princess.name)),
            DataCell(Text('$count')),
            DataCell(Text('${percentage.toStringAsFixed(1)}%')),
          ],
        ),
      );
    }
    
    return rows;
  }
}

// Recent scan item widget
class _RecentScanItem extends StatelessWidget {
  final Map<String, dynamic> scan;

  const _RecentScanItem({required this.scan});

  @override
  Widget build(BuildContext context) {
    final timestamp = scan['timestamp'] as dynamic;
    final dateTime = (timestamp != null) ? (timestamp as Timestamp).toDate() : DateTime.now();
    final formattedTime = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan['princessName'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  'Confidence: ${scan['confidence'] ?? '0.00'}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            formattedTime,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}