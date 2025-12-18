import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';

class FirebaseService {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Test method to verify Firestore connectivity
  Future<void> testFirestoreConnection() async {
    try {
      print('Testing Firestore connection...');
      final testDoc = await _firestore.collection('test').add({
        'test': 'connection',
        'timestamp': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      print('Test document created with ID: ${testDoc.id}');
      
      // Clean up test document
      await testDoc.delete();
      print('Test document deleted');
    } on TimeoutException catch (e) {
      print('Firestore connection test timed out: $e');
      print('This typically indicates network connectivity issues');
    } catch (e) {
      print('Firestore connection test failed: $e');
    }
  }
  
  // Method to verify Firebase configuration
  Future<bool> verifyConfiguration() async {
    try {
      print('Verifying Firebase configuration...');
      
      // Configure Firestore settings for better connectivity
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        sslEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      // Check if we can access Firestore
      final firestore = FirebaseFirestore.instance;
      print('Firestore instance accessible: $firestore');
      
      // Check if we can access Auth
      final auth = FirebaseAuth.instance;
      print('Auth instance accessible: $auth');
      
      // Test anonymous sign-in with timeout
      print('Testing anonymous sign-in...');
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously()
        .timeout(const Duration(seconds: 10));
      User? user = userCredential.user;
      print('Anonymous sign-in successful. User ID: ${user?.uid}');
      
      // Sign out
      await FirebaseAuth.instance.signOut();
      print('Signed out after configuration test');
      
      print('Firebase configuration verified successfully!');
      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth configuration error: ${e.code} - ${e.message}');
      if (e.code == 'CONFIGURATION_NOT_FOUND') {
        print('CONFIGURATION_NOT_FOUND: Firebase configuration issue detected');
        print('Troubleshooting steps:');
        print('1. Ensure Anonymous sign-in is enabled in Firebase Console -> Authentication -> Sign-in method');
        print('2. Verify google-services.json is in android/app/ directory');
        print('3. Confirm package name matches exactly: com.example.disney_princess_app');
        print('4. Check internet connectivity');
        print('5. Make sure you have a stable internet connection when the app starts');
      }
      return false;
    } on TimeoutException catch (e) {
      print('Firebase configuration test timed out: $e');
      print('This typically indicates network connectivity issues');
      print('Troubleshooting steps:');
      print('1. Check your internet connection');
      print('2. Try switching between Wi-Fi and mobile data');
      print('3. Restart your device');
      print('4. Check if your network blocks Firebase services');
      return false;
    } on FirebaseException catch (e) {
      print('Firebase configuration error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Configuration verification failed: $e');
      return false;
    }
  }

  // Alias for verifyConfiguration to match the method call in homepage_screen.dart
  Future<void> verifyFirebaseConfiguration() async {
    await verifyConfiguration();
  }

  // Authentication methods
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error during email sign-in: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error during user creation: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error during sign-out: ${e.code} - ${e.message}');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Firestore methods
  Future<void> addUser(User user) async {
    try {
      print('Adding user to Firestore: ${user.uid}');
      
      // Validate user data
      if (user.uid.isEmpty) {
        print('Error: User UID is empty');
        return;
      }
      
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 15));
      print('User added to Firestore successfully: ${user.uid}');
    } on TimeoutException catch (e) {
      print('Timeout adding user to Firestore: $e');
      print('This may indicate network connectivity issues');
    } on FirebaseException catch (e) {
      print('Firebase error adding user: ${e.code} - ${e.message}');
    } catch (e) {
      print('Error adding user to Firestore: $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
    }
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get()
        .timeout(const Duration(seconds: 10));
    } on TimeoutException catch (e) {
      print('Timeout getting user from Firestore: $e');
      print('This may indicate network connectivity issues');
      rethrow;
    } catch (e) {
      print('Error getting user from Firestore: $e');
      rethrow;
    }
  }

  Future<void> savePrincessClassification(String userId, Map<String, dynamic> data) async {
    try {
      print('Saving princess classification for user: $userId');
      print('Data to save: $data');
      
      // Validate data before saving
      if (userId.isEmpty) {
        print('Error: userId is empty');
        return;
      }
      
      // Validate that data contains expected fields
      if (!data.containsKey('princessName') || !data.containsKey('confidence')) {
        print('Error: Missing required data fields');
        print('Data keys: ${data.keys}');
        return;
      }
      
      // Check if allResults is serializable
      if (data.containsKey('allResults')) {
        final allResults = data['allResults'];
        print('Checking allResults serialization:');
        print('- Type: ${allResults.runtimeType}');
        print('- Length: ${allResults is List ? allResults.length : "N/A"}');
        
        // Check if allResults contains valid map entries
        if (allResults is List) {
          for (int i = 0; i < allResults.length && i < 3; i++) { // Only check first 3 for brevity
            final item = allResults[i];
            print('- Item $i: type=${item.runtimeType}, keys=${item is Map ? item.keys : "N/A"}');
          }
        }
      }
      
      final docRef = await _firestore.collection('classifications').add({
        'userId': userId,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 15));
      print('Classification saved successfully with ID: ${docRef.id}');
    } on TimeoutException catch (e) {
      print('Timeout saving classification: $e');
      print('This may indicate network connectivity issues');
    } on FirebaseException catch (e) {
      print('Firebase error saving classification: ${e.code} - ${e.message}');
    } catch (e) {
      print('Error saving classification: $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
    }
  }

  // Storage methods
  Future<String?> uploadImage(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      Reference storageRef = _storage.ref().child('images/$fileName');
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask.timeout(const Duration(seconds: 30));
      return await snapshot.ref.getDownloadURL();
    } on TimeoutException catch (e) {
      print('Timeout uploading image: $e');
      print('This may indicate network connectivity issues');
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<Map<String, int>> getPrincessScanCounts() async {
    try {
      print('Fetching princess scan counts from Firestore');
      
      // Query all classifications
      final querySnapshot = await _firestore.collection('classifications')
        .orderBy('timestamp', descending: true)
        .limit(1000) // Limit to avoid performance issues
        .get()
        .timeout(const Duration(seconds: 15));
      
      print('Found ${querySnapshot.docs.length} classification documents');
      
      // Initialize counts for all princesses
      final scanCounts = <String, int>{};
      
      // Process each classification document
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data()['data'];
          if (data != null && data['princessName'] != null) {
            final princessName = data['princessName'] as String;
            // Exclude 'unknown' princesses from scan counts (these are black images/invalid scans)
            if (princessName != 'unknown') {
              scanCounts[princessName] = (scanCounts[princessName] ?? 0) + 1;
            }
          }
        } catch (docError) {
          print('Error processing document ${doc.id}: $docError');
        }
      }
      
      print('Final scan counts: $scanCounts');
      return scanCounts;
    } on TimeoutException catch (e) {
      print('Timeout fetching princess scan counts: $e');
      return {};
    } catch (e) {
      print('Error fetching princess scan counts: $e');
      return {};
    }
  }
  
  // Getters for Firebase instances
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
}