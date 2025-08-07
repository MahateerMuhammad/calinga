import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'careseeker_profile.dart';
import 'find_care_screen.dart';
import 'my_bookings_screen.dart';

class CareseekerHome extends StatefulWidget {
  const CareseekerHome({super.key});

  @override
  State<CareseekerHome> createState() => _CareseekerHomeState();
}

class _CareseekerHomeState extends State<CareseekerHome> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  UserModel? _currentUser;
  bool _isLoadingUser = true;

  // Pages to display based on bottom navigation
  late final List<Widget> _pages = [
    const CareseekerHomePage(),
    const FindCareScreen(),
    const CareseekerProfileScreen(),
    const MyBookingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
      appBar: AppBar(
        title: const Text('CALiNGA'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
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
                      Icons.search_outlined,
                      color: Colors.black87,
                      size: 24,
                    ),
                    title: const Text(
                      'Find Care',
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
                      Icons.calendar_today_outlined,
                      color: Colors.black87,
                      size: 24,
                    ),
                    title: const Text(
                      'My Bookings',
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
    );
  }
}

// Home Page
class CareseekerHomePage extends StatelessWidget {
  const CareseekerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('CareSeeker Home Page'));
  }
}

// Find Care Page
class FindCarePage extends StatelessWidget {
  const FindCarePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Find Care Page'));
  }
}

// Profile Page
class CareseekerProfilePage extends StatelessWidget {
  const CareseekerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('CareSeeker Profile Page'));
  }
}

// My Bookings Page
class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('My Bookings Page'));
  }
}
