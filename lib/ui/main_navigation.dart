import 'package:flutter/material.dart';
import 'package:project/ui/settings_screen.dart';
import 'package:project/ui/camera_screen.dart';
import 'package:project/ui/profile_screen.dart';
import 'package:project/utils/animation_config.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 1; // Default to Camera

  static final List<Widget> _screens = [
    const SettingsScreen(),
    const CameraScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: AppAnimations.normal,
        switchInCurve: AppAnimations.easeOutCubic,
        switchOutCurve: AppAnimations.easeOutCubic,
        transitionBuilder: (child, animation) {
          // Slide transition based on direction
          final isForward = _selectedIndex >= (_selectedIndex == 0 ? 0 : _selectedIndex - 1);
          final offset = isForward ? const Offset(0.15, 0) : const Offset(-0.15, 0);
          return SlideTransition(
            position: Tween<Offset>(
              begin: offset,
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppAnimations.easeOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'Chụp ảnh',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF00FFCC),
        unselectedItemColor: Colors.white38,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        selectedFontSize: 12,
        unselectedFontSize: 12,
      ),
    );
  }
}