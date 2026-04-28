import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/storage/auth_storage.dart';
import '../discover/discover_view.dart';
import '../map/map_view.dart';
import '../profile/profile_view.dart';
import 'feed_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();

  /// Lets nested screens (e.g. feed empty state) jump to a different bottom-nav tab.
  static void goToTab(int index) => _HomeViewState._activeState?._goTo(index);
}

class _HomeViewState extends State<HomeView> {
  int _index = 0;
  static _HomeViewState? _activeState;

  @override
  void initState() {
    super.initState();
    _activeState = this;
  }

  @override
  void dispose() {
    if (_activeState == this) _activeState = null;
    super.dispose();
  }

  void _goTo(int i) {
    if (mounted) setState(() => _index = i);
  }

  late final List<Widget> _pages = [
    const FeedView(),
    const MapView(),
    const SizedBox(),
    const DiscoverView(),
    ProfileView(userId: AuthStorage.userId),
  ];

  static const _titles = ['CookShare', 'Nearby map', 'CookShare', 'Discover', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final showAppBar = _index != 1; // Map is full-bleed
    return Scaffold(
      extendBody: true,
      appBar: showAppBar
          ? AppBar(
              titleSpacing: 20,
              title: Text(_titles[_index]),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CircleIconButton(
                    icon: Icons.search,
                    onTap: () => Get.toNamed(AppRoutes.search),
                  ),
                ),
              ],
            )
          : null,
      body: _pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.hairline)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _index,
            backgroundColor: Colors.transparent,
            elevation: 0,
            onDestinationSelected: (i) {
              if (i == 2) {
                Get.toNamed(AppRoutes.createPost);
                return;
              }
              setState(() => _index = i);
            },
            destinations: [
              const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Feed'),
              const NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: 'Map'),
              NavigationDestination(
                icon: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.seed, const Color(0xFFC44318)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.seed.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                ),
                label: '',
              ),
              const NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded), label: 'Discover'),
              const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'Me'),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.hairline),
        ),
        child: Icon(icon, color: AppTheme.ink, size: 20),
      ),
    );
  }
}
