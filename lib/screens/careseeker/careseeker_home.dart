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
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppConstants.primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: _currentUser?.profileImageUrl != null
                        ? NetworkImage(_currentUser!.profileImageUrl!)
                        : null,
                    child: _currentUser?.profileImageUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: AppConstants.primaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isLoadingUser
                        ? 'Loading...'
                        : _currentUser?.fullName ?? 'User Name',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    _isLoadingUser
                        ? 'Loading...'
                        : _currentUser?.email ?? 'user@example.com',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: _selectedIndex == 0,
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Find Care'),
              selected: _selectedIndex == 1,
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              selected: _selectedIndex == 2,
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('My Bookings'),
              selected: _selectedIndex == 3,
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Sign Out'),
              onTap: _signOut,
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
