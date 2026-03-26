import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/shared/theme/app_theme.dart';
import 'src/features/dashboard/presentation/dashboard_screen.dart';
import 'src/features/video_generator/presentation/video_generator_wrapper.dart';
// import 'src/features/facebook_post/presentation/facebook_post_screen.dart';
import 'src/features/property_post/presentation/property_post_screen.dart';
import 'src/shared/widgets/app_sidebar.dart';
import 'src/shared/widgets/app_header.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Land Sales Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _menuItems = const [
    {'icon': Icons.dashboard, 'label': 'Dashboard'},
    {'icon': Icons.video_library, 'label': 'Video Generator'},
    // {'icon': Icons.facebook, 'label': 'Facebook Post'},
    {'icon': Icons.post_add, 'label': 'Create Post'},
  ];

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const VideoGeneratorWrapper();
      // case 2:
      //   return const FacebookPostScreen();
      case 2:
        return const PropertyPostScreen();
      default:
        return const DashboardScreen();
    }
  }

  String _getPageTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Land Sales Dashboard';
      case 1:
        return 'Video Generator';
      // case 2:
      //   return 'Facebook Post';
      case 2:
        return 'Create Post';
      default:
        return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            menuItems: _menuItems,
            currentIndex: _currentIndex,
            onItemTap: (index) => setState(() => _currentIndex = index),
          ),
          Expanded(
            child: Column(
              children: [
                AppHeader(title: _getPageTitle()),
                Expanded(child: _getCurrentPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
