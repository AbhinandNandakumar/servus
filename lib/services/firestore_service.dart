import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get workers by category
  Future<List<Map<String, dynamic>>> getWorkersByCategory(String category) async {
    try {
      final snapshot = await _db
          .collection('workers')
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Include document ID
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching workers: $e');
      return [];
    }
  }

  // Get all workers
  Future<List<Map<String, dynamic>>> getAllWorkers() async {
    try {
      final snapshot = await _db.collection('workers').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching all workers: $e');
      return [];
    }
  }

  // Get a single worker by ID
  Future<Map<String, dynamic>?> getWorkerById(String workerId) async {
    try {
      final doc = await _db.collection('workers').doc(workerId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching worker: $e');
      return null;
    }
  }

  // Add a new worker (for worker registration)
  Future<String?> addWorker(Map<String, dynamic> workerData) async {
    try {
      final docRef = await _db.collection('workers').add(workerData);
      return docRef.id;
    } catch (e) {
      print('Error adding worker: $e');
      return null;
    }
  }

  // Update worker data
  Future<bool> updateWorker(String workerId, Map<String, dynamic> data) async {
    try {
      await _db.collection('workers').doc(workerId).update(data);
      return true;
    } catch (e) {
      print('Error updating worker: $e');
      return false;
    }
  }

  // Create a booking
  Future<String?> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final docRef = await _db.collection('bookings').add({
        ...bookingData,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      return docRef.id;
    } catch (e) {
      print('Error creating booking: $e');
      return null;
    }
  }

  // Get bookings for a worker
  Future<List<Map<String, dynamic>>> getWorkerBookings(String workerId) async {
    try {
      final snapshot = await _db
          .collection('bookings')
          .where('workerId', isEqualTo: workerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }

  // Get all bookings (for user booking history)
  Future<List<Map<String, dynamic>>> getAllBookings() async {
    try {
      final snapshot = await _db
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching all bookings: $e');
      return [];
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      await _db.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
    }
  }

  // Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    return updateBookingStatus(bookingId, 'cancelled');
  }

  // Seed initial workers data (run once to populate Firestore)
  Future<void> seedWorkersData() async {
    final workersData = [
      {
        'name': 'Ramesh',
        'category': 'plumber',
        'location': 'Mumbai',
        'rating': 4.7,
        'hourly_rate': 45,
        'experience': '8 years exp.',
        'verified': true,
      },
      {
        'name': 'Suresh',
        'category': 'electrician',
        'location': 'Delhi',
        'rating': 4.5,
        'hourly_rate': 50,
        'experience': '6 years exp.',
        'verified': true,
      },
      {
        'name': 'Amit',
        'category': 'ac_technician',
        'location': 'Bangalore',
        'rating': 4.6,
        'hourly_rate': 55,
        'experience': '5 years exp.',
        'verified': true,
      },
      {
        'name': 'Vikram',
        'category': 'carpenter',
        'location': 'Chennai',
        'rating': 4.8,
        'hourly_rate': 40,
        'experience': '12 years exp.',
        'verified': true,
      },
      {
        'name': 'Sunil',
        'category': 'appliance_repair',
        'location': 'Pune',
        'rating': 4.4,
        'hourly_rate': 35,
        'experience': '4 years exp.',
        'verified': true,
      },
      {
        'name': 'Anil',
        'category': 'glazier',
        'location': 'Hyderabad',
        'rating': 4.7,
        'hourly_rate': 42,
        'experience': '7 years exp.',
        'verified': true,
      },
      {
        'name': 'Meena',
        'category': 'cleaning',
        'location': 'Kolkata',
        'rating': 4.5,
        'hourly_rate': 25,
        'experience': '3 years exp.',
        'verified': true,
      },
      {
        'name': 'Rohit',
        'category': 'computer_repair',
        'location': 'Bangalore',
        'rating': 4.6,
        'hourly_rate': 60,
        'experience': '5 years exp.',
        'verified': true,
      },
      {
        'name': 'Deepak',
        'category': 'general_contractor',
        'location': 'Delhi',
        'rating': 4.6,
        'hourly_rate': 55,
        'experience': '10 years exp.',
        'verified': true,
      },
      {
        'name': 'Aakash',
        'category': 'mobile_repair',
        'location': 'Mumbai',
        'rating': 4.5,
        'hourly_rate': 30,
        'experience': '4 years exp.',
        'verified': true,
      },
      {
        'name': 'Kiran',
        'category': 'pest_control',
        'location': 'Chennai',
        'rating': 4.7,
        'hourly_rate': 45,
        'experience': '6 years exp.',
        'verified': true,
      },
      {
        'name': 'Ananya',
        'category': 'home_automation',
        'location': 'Bangalore',
        'rating': 4.6,
        'hourly_rate': 70,
        'experience': '5 years exp.',
        'verified': true,
      },
      {
        'name': 'Rajat',
        'category': 'solar_technician',
        'location': 'Pune',
        'rating': 4.8,
        'hourly_rate': 65,
        'experience': '7 years exp.',
        'verified': true,
      },
      {
        'name': 'Sneha',
        'category': 'specialized_services',
        'location': 'Delhi',
        'rating': 4.6,
        'hourly_rate': 50,
        'experience': '8 years exp.',
        'verified': true,
      },
      {
        'name': 'Manish',
        'category': 'gas_technician',
        'location': 'Chennai',
        'rating': 4.5,
        'hourly_rate': 48,
        'experience': '6 years exp.',
        'verified': true,
      },
      {
        'name': 'Ajay',
        'category': 'automobile_mechanic',
        'location': 'Mumbai',
        'rating': 4.6,
        'hourly_rate': 55,
        'experience': '9 years exp.',
        'verified': true,
      },
      {
        'name': 'Vikas',
        'category': 'locksmith',
        'location': 'Delhi',
        'rating': 4.5,
        'hourly_rate': 35,
        'experience': '5 years exp.',
        'verified': true,
      },
      {
        'name': 'Ravi',
        'category': 'welder',
        'location': 'Bangalore',
        'rating': 4.7,
        'hourly_rate': 50,
        'experience': '8 years exp.',
        'verified': true,
      },
    ];

    // Check if workers collection is empty
    final existingWorkers = await _db.collection('workers').limit(1).get();
    if (existingWorkers.docs.isEmpty) {
      print('Seeding workers data...');
      for (final worker in workersData) {
        await _db.collection('workers').add(worker);
      }
      print('Workers data seeded successfully!');
    } else {
      print('Workers collection already has data, skipping seed.');
    }
  }
}
