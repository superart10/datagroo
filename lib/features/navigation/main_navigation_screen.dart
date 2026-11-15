import 'package:material_ui/material_ui.dart';
import 'package:datagroo/core/l10n/app_language.dart';
import 'package:datagroo/features/home/screens/home_dashboard_screen.dart';
import 'package:datagroo/features/plots/screens/plots_list_screen.dart';
import 'package:datagroo/features/climate/screens/climate_screen.dart';
import 'package:datagroo/features/crops/screens/crops_list_screen.dart';
import 'package:datagroo/features/profile/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLanguage.watch(context);
    const primaryColor = Color(0xFF2E7D32);

    final List<Widget> screens = [
      HomeDashboardScreen(onNavigateToTab: _onTabSelected),
      const PlotsListScreen(),
      const ClimateScreen(),
      const CropsListScreen(),
      ProfileScreen(onNavigateToTab: _onTabSelected),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade300,
              width: 0.8,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: tr('Inicio', 'Home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: tr('Terrenos', 'Plots'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.wb_sunny_outlined),
              activeIcon: Icon(Icons.wb_sunny),
              label: tr('Clima', 'Weather'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.eco_outlined),
              activeIcon: Icon(Icons.eco),
              label: tr('Cultivos', 'Crops'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: tr('Perfil', 'Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
