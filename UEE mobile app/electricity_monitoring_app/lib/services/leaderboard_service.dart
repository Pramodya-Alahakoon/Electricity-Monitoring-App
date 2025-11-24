import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class LeaderboardEntry {
  final String userId;
  final String name;
  final String email;
  final int points;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.email,
    required this.points,
    required this.rank,
  });
}

class LeaderboardService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoading = false;
  String? _error;

  List<LeaderboardEntry> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get current user's rank
  int? getCurrentUserRank() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return null;

    final index = _leaderboard.indexWhere(
      (entry) => entry.userId == currentUserId,
    );
    return index >= 0 ? index + 1 : null;
  }

  // Get current user's points
  int? getCurrentUserPoints() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return null;

    final entry = _leaderboard.firstWhere(
      (entry) => entry.userId == currentUserId,
      orElse: () =>
          LeaderboardEntry(userId: '', name: '', email: '', points: 0, rank: 0),
    );

    return entry.userId.isNotEmpty ? entry.points : null;
  }

  // Update user points
  Future<void> updateUserPoints(int points) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'points': points,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reload leaderboard to reflect changes
      await loadLeaderboard();
    } catch (e) {
      debugPrint('Error updating user points: $e');
      _error = 'Failed to update points';
      notifyListeners();
    }
  }

  // Load leaderboard
  Future<void> loadLeaderboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get all users (not just those with points field)
      final querySnapshot = await _firestore
          .collection('users')
          .limit(100) // Get up to 100 users
          .get();

      // Create leaderboard entries with default 0 points for users without points field
      final entries = querySnapshot.docs.map((doc) {
        final data = doc.data();

        return LeaderboardEntry(
          userId: doc.id,
          name: data['name'] ?? 'Unknown User',
          email: data['email'] ?? '',
          points:
              data['points'] ?? 0, // Default to 0 if points field doesn't exist
          rank: 0, // Will be set after sorting
        );
      }).toList();

      // Sort by points in descending order
      entries.sort((a, b) => b.points.compareTo(a.points));

      // Assign ranks after sorting
      _leaderboard = entries.asMap().entries.map((entry) {
        final index = entry.key;
        final leaderboardEntry = entry.value;

        return LeaderboardEntry(
          userId: leaderboardEntry.userId,
          name: leaderboardEntry.name,
          email: leaderboardEntry.email,
          points: leaderboardEntry.points,
          rank: index + 1,
        );
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
      _error = 'Failed to load leaderboard';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Listen to real-time updates
  Stream<List<LeaderboardEntry>> getLeaderboardStream() {
    return _firestore.collection('users').limit(100).snapshots().map((
      snapshot,
    ) {
      // Create entries with default 0 points for users without points field
      final entries = snapshot.docs.map((doc) {
        final data = doc.data();

        return LeaderboardEntry(
          userId: doc.id,
          name: data['name'] ?? 'Unknown User',
          email: data['email'] ?? '',
          points:
              data['points'] ?? 0, // Default to 0 if points field doesn't exist
          rank: 0, // Will be set after sorting
        );
      }).toList();

      // Sort by points in descending order
      entries.sort((a, b) => b.points.compareTo(a.points));

      // Assign ranks after sorting
      return entries.asMap().entries.map((entry) {
        final index = entry.key;
        final leaderboardEntry = entry.value;

        return LeaderboardEntry(
          userId: leaderboardEntry.userId,
          name: leaderboardEntry.name,
          email: leaderboardEntry.email,
          points: leaderboardEntry.points,
          rank: index + 1,
        );
      }).toList();
    });
  }
}
