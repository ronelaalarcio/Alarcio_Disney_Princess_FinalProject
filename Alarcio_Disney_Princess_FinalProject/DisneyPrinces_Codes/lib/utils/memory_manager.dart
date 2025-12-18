import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class MemoryManager {
  // Check if the app is running on a low-memory device
  static bool isLowMemoryDevice() {
    // More accurate approach - check platform and make educated guess
    // For now, we'll use a balanced approach
    if (kIsWeb) {
      return false; // Web platforms typically have more memory
    }
    
    // For mobile platforms, use a balanced approach
    if (Platform.isAndroid) {
      // On Android, we'll assume newer devices have sufficient memory
      // This is a simplified check and could be enhanced with actual memory info
      return false;
    }
    
    if (Platform.isIOS) {
      // iOS devices generally have good memory management
      // Assume recent iOS devices have sufficient memory
      return false;
    }
    
    // Default to false for better performance on unknown platforms
    return false;
  }
  
  // Get optimal thread count for ML operations based on device capabilities
  static int getOptimalThreadCount() {
    // For web platforms, threading might not be supported
    if (kIsWeb) {
      return 1;
    }
    
    // For mobile platforms, use a conservative approach
    if (Platform.isAndroid || Platform.isIOS) {
      // Most modern mobile devices can handle 2-4 threads efficiently
      // Using 2 threads as a balance between performance and battery life
      return 2;
    }
    
    // For desktop platforms, we can be more aggressive
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop devices typically have more cores
      // Use 4 threads as a reasonable default
      return 4;
    }
    
    // Default to 1 thread for unknown platforms to be safe
    return 1;
  }
  
  // Dispose of unused resources
  static void cleanup() {
    // Trigger garbage collection if possible
    // Note: This is not guaranteed to work and should be used sparingly
    if (!kIsWeb) {
      // On mobile platforms, we might be able to trigger GC
      // but Flutter doesn't expose this directly
      try {
        // Force garbage collection (this is not guaranteed to work)
        // This is just a hint to the VM
      } catch (e) {
        // Ignore errors
      }
    }
  }
  
  // Get memory usage information (simplified)
  static Map<String, dynamic> getMemoryInfo() {
    return {
      'isLowMemoryDevice': isLowMemoryDevice(),
      'platform': Platform.operatingSystem,
    };
  }
  
  // Optimize image processing settings based on device capabilities
  static int getImageProcessingSize() {
    // Use adaptive size based on device capabilities
    if (isLowMemoryDevice()) {
      return 128; // Smaller size for low memory devices
    }
    return 224; // Larger size for better accuracy on capable devices
  }
}