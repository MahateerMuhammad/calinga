import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../providers/availability_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/availability_toggle.dart';
import '../../widgets/booking_card.dart';
import '../auth/login_screen.dart';
import 'caregiver_profile.dart';
import 'documents_screen.dart';
import 'all_bookings_screen.dart';

class CaregiverHome extends StatefulWidget {
  const CaregiverHome({super.key});

  @override
  State<CaregiverHome> createState() => _CaregiverHomeState();
}

class _CaregiverHomeState extends State<CaregiverHome> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  UserModel? _currentUser;
  bool _isLoadingUser = true;

  // Pages to display based on bottom navigation
  late final List<Widget> _pages = [
    const CaregiverHomePage(),
    const AllBookingsScreen(),
    const CaregiverProfileScreen(),
    const DocumentsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    // Initialize location provider
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    await locationProvider.initializeLocation();

    // Initialize availability provider
    final availabilityProvider = Provider.of<AvailabilityProvider>(
      context,
      listen: false,
    );
    await availabilityProvider.initializeAvailability();

    // Initialize booking provider
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );
    bookingProvider.setUserRole('CALiNGApro');
    await bookingProvider.initialize();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getCurrentUserData();
      setState(() {
        _currentUser = userData;
        _isLoadingUser = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
      });
      print('Error loading user data: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.medical_services,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'CALiNGA Care Pro',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.orange, size: 28),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            // Custom Header
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage: _currentUser?.profileImageUrl != null
                        ? NetworkImage(_currentUser!.profileImageUrl!)
                        : null,
                    child: _currentUser?.profileImageUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Color(0xFF4A90E2),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isLoadingUser
                        ? 'Loading...'
                        : _currentUser?.fullName ?? 'User Name',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLoadingUser
                        ? 'Loading...'
                        : _currentUser?.email ?? 'user@example.com',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.home_outlined,
                      color: Colors.black87,
                      size: 24,
                    ),
                    title: const Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    selected: _selectedIndex == 0,
                    onTap: () {
                      _onItemTapped(0);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.description_outlined,
                      color: Colors.black87,
                      size: 24,
                    ),
                    title: const Text(
                      'All Bookings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    selected: _selectedIndex == 1,
                    onTap: () {
                      _onItemTapped(1);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.person_outline,
                      color: Colors.black87,
                      size: 24,
                    ),
                    title: const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    selected: _selectedIndex == 2,
                    onTap: () {
                      _onItemTapped(2);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.folder_outlined,
                      color: Colors.black87,
                      size: 24,
                    ),
                    title: const Text(
                      'Documents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    selected: _selectedIndex == 3,
                    onTap: () {
                      _onItemTapped(3);
                      Navigator.pop(context);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color: Colors.grey),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.logout_outlined,
                      color: Colors.black87,
                      size: 24,
                    ),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    onTap: _signOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                // Refresh functionality
                final availabilityProvider = Provider.of<AvailabilityProvider>(
                  context,
                  listen: false,
                );
                final bookingProvider = Provider.of<BookingProvider>(
                  context,
                  listen: false,
                );

                await availabilityProvider.refreshAvailability();
                await bookingProvider.refresh();
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
    );
  }
}

// Home Page
class CaregiverHomePage extends StatelessWidget {
  const CaregiverHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AvailabilityProvider, BookingProvider>(
      builder: (context, availabilityProvider, bookingProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          availabilityProvider.statusDisplayText,
                          style: TextStyle(
                            fontSize: 16,
                            color: availabilityProvider.isAvailable
                                ? Colors.green[700]
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const AvailabilityToggle(),
                ],
              ),

              const SizedBox(height: 24),

              // Quick Stats
              _buildQuickStats(bookingProvider),

              const SizedBox(height: 24),

              // Today's Bookings Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today\'s Bookings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Today's Bookings List
              _buildTodayBookings(bookingProvider),

              const SizedBox(height: 24),

              // Recent Activity
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              _buildRecentActivity(bookingProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(BookingProvider bookingProvider) {
    final stats = bookingProvider.getBookingStats();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Bookings',
              stats['totalBookings'].toString(),
              Icons.calendar_today,
              Colors.blue,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Today\'s Bookings',
              stats['todaysBookings'].toString(),
              Icons.today,
              Colors.purple,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Completed',
              stats['completedBookings'].toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Earnings',
              '\$${stats['totalEarnings'].toStringAsFixed(0)}',
              Icons.attach_money,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTodayBookings(BookingProvider bookingProvider) {
    final todayBookings = bookingProvider.getTodaysBookings();

    if (todayBookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings for today',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your schedule is clear for today',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: todayBookings
          .map(
            (booking) => BookingCard(
              booking: booking,
              onTap: () {
                // TODO: Navigate to booking details
              },
              onCancel: () {
                // TODO: Show cancel confirmation
              },
              isCompact: true,
            ),
          )
          .toList(),
    );
  }

  Widget _buildRecentActivity(BookingProvider bookingProvider) {
    final recentBookings = bookingProvider.bookings.take(3).toList();

    if (recentBookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.history, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No recent activity',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: recentBookings
          .map(
            (booking) => CompactBookingCard(
              booking: booking,
              onTap: () {
                // TODO: Navigate to booking details
              },
            ),
          )
          .toList(),
    );
  }
}

// All Bookings Page
class AllBookingsPage extends StatelessWidget {
  const AllBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('All Bookings Page'));
  }
}

// Profile Page
class CaregiverProfilePage extends StatelessWidget {
  const CaregiverProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('CALiNGApro Profile Page'));
  }
}

// Documents Page
class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Documents Page'));
  }
}
