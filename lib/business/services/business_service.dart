import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/business_model.dart';

class BusinessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> registerBusiness(Business business) async {
    try {
      await _firestore
          .collection('businesses')
          .doc(business.id)
          .set(business.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('Error registering business: $e');
      }
      throw Exception('Failed to register business: $e');
    }
  }

  Future<Business?> getBusiness(String id) async {
    try {
      final doc = await _firestore.collection('businesses').doc(id).get();
      if (kDebugMode) {
        print('Getting business document: ${doc.exists}');
        if (doc.exists) {
          print('Document data: ${doc.data()}');
        }
      }
      return doc.exists ? Business.fromJson(doc.data()!) : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting business: $e');
      }
      return null;
    }
  }

  Future<String> uploadLicenseImage(
      String businessId, File file, String type) async {
    try {
      if (kDebugMode) {
        print(
            'Starting image upload. File exists: ${file.existsSync()}, Size: ${file.lengthSync()} bytes');
      }

      // Create a reference to the storage location with a unique filename
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref =
          _storage.ref().child('businesses/$businessId/$type/$fileName');

      // Set metadata to ensure proper content type
      final metadata = SettableMetadata(
        contentType: 'image/jpeg', // Adjust if you need other formats
      );

      // Upload the file with metadata
      final uploadTask = ref.putFile(file, metadata);

      // Listen to upload progress (for debugging)
      if (kDebugMode) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          print(
              'Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes');
        });
      }

      // Wait for the upload to complete
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        print('Upload successful. Download URL: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
      throw Exception('Failed to upload image: $e');
    }
  }
}
