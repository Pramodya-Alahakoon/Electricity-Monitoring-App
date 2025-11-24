import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/leaderboard_service.dart';
import '../../utils/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Load leaderboard when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardService>().loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Consumer<LeaderboardService>(
        builder: (context, leaderboardService, child) {
          if (leaderboardService.isLoading &&
              leaderboardService.leaderboard.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (leaderboardService.error != null &&
              leaderboardService.leaderboard.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    leaderboardService.error!,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => leaderboardService.loadLeaderboard(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final leaderboard = leaderboardService.leaderboard;

          if (leaderboard.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.leaderboard,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No leaderboard data available',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Find current user's entry
          final currentUserEntry = leaderboard.firstWhere(
            (entry) => entry.userId == currentUserId,
            orElse: () => LeaderboardEntry(
              userId: '',
              name: '',
              email: '',
              points: 0,
              rank: 0,
            ),
          );

          final hasCurrentUserEntry = currentUserEntry.userId.isNotEmpty;

          return RefreshIndicator(
            onRefresh: () => leaderboardService.loadLeaderboard(),
            child: CustomScrollView(
              slivers: [
                // Leaderboard Title
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: const Center(
                      child: Text(
                        'Leaderboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),

                // Current User Card (if exists)
                if (hasCurrentUserEntry)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildCurrentUserCard(currentUserEntry),
                    ),
                  ),

                // Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.leaderboard,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Top Rankings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Leaderboard List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = leaderboard[index];
                      final isCurrentUser = entry.userId == currentUserId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildLeaderboardCard(entry, isCurrentUser),
                      );
                    }, childCount: leaderboard.length),
                  ),
                ),

                // Bottom Spacing
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentUserCard(LeaderboardEntry entry) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Your Rank',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRankBadge(entry.rank),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.points}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'pts',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            entry.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, bool isCurrentUser) {
    Color? backgroundColor;
    Color? textColor;

    // Special styling for top 3
    if (entry.rank == 1) {
      // Gold - 1st Place (Darker gold)
      backgroundColor = const Color(0xFFFFC107); // Rich darker gold background
      textColor = const Color(0xFF795548); // Dark brown text
    } else if (entry.rank == 2) {
      // Silver - 2nd Place
      backgroundColor = const Color(0xFFE0E0E0); // Medium silver background
      textColor = const Color(0xFF424242); // Very dark grey text
    } else if (entry.rank == 3) {
      // Bronze - 3rd Place (Lighter)
      backgroundColor = const Color(
        0xFFFFF3E0,
      ); // Very light bronze/peach background
      textColor = const Color(0xFFD84315); // Bright orange-red text
    } else if (isCurrentUser) {
      backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
      textColor = AppTheme.primaryColor;
    } else {
      backgroundColor = Colors.white;
      textColor = Colors.black87;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser && entry.rank > 3
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          _buildRankBadge(entry.rank, small: true),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isCurrentUser)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'You',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: entry.rank <= 3
                  ? Colors.white.withOpacity(0.7)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.stars, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 6),
                Text(
                  '${entry.points}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank, {bool small = false}) {
    IconData icon;
    Color color;
    double size = small ? 40 : 60;
    double iconSize = small ? 24 : 32;

    if (rank == 1) {
      // Gold Trophy - 1st Place (Bright gold for visibility on dark background)
      icon = Icons.emoji_events;
      color = const Color(0xFFFFEB3B); // Bright yellow-gold color
    } else if (rank == 2) {
      // Silver Trophy - 2nd Place
      icon = Icons.emoji_events;
      color = const Color(0xFF9E9E9E); // Medium silver/grey color
    } else if (rank == 3) {
      // Bronze Trophy - 3rd Place (Lighter bronze)
      icon = Icons.emoji_events;
      color = const Color(0xFFFF6F00); // Bright orange color
    } else {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$rank',
            style: TextStyle(
              fontSize: small ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(icon, color: color, size: iconSize),
          ),
          if (!small)
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
