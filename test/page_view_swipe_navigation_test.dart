import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test widget mimicking MainShell navigation structure for isolated, fast widget testing
class TestShellNavigation extends StatefulWidget {
  const TestShellNavigation({super.key});

  @override
  State<TestShellNavigation> createState() => _TestShellNavigationState();
}

class _TestShellNavigationState extends State<TestShellNavigation> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _TestKeepAliveTab(name: 'HomeTab'),
      const _TestKeepAliveTab(name: 'AqaidTab'),
      const _TestKeepAliveTab(name: 'MasailTab'),
      const _TestKeepAliveTab(name: 'QATab'),
      const _TestKeepAliveTab(name: 'ProfileTab'),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const PageScrollPhysics(),
        onPageChanged: (index) {
          if (_currentIndex != index) {
            setState(() => _currentIndex = index);
          }
        },
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Aqaid'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Masail'),
          BottomNavigationBarItem(icon: Icon(Icons.question_answer), label: 'Q&A'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _TestKeepAliveTab extends StatefulWidget {
  final String name;
  const _TestKeepAliveTab({required this.name});

  @override
  State<_TestKeepAliveTab> createState() => _TestKeepAliveTabState();
}

class _TestKeepAliveTabState extends State<_TestKeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  int tapCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.name),
          Text('Taps: $tapCount'),
          ElevatedButton(
            onPressed: () => setState(() => tapCount++),
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PageView Swipe Navigation & Bottom Navigation Bar Synchronization Tests', () {
    testWidgets('Initializes at Home tab (index 0) with PageView showing HomeTab', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestShellNavigation(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HomeTab'), findsOneWidget);
      expect(find.text('AqaidTab'), findsNothing);

      final bottomNav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.currentIndex, equals(0));
    });

    testWidgets('Tapping bottom nav icon animates PageView and highlights corresponding tab', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestShellNavigation(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Aqaid' tab (index 1)
      await tester.tap(find.text('Aqaid'));
      await tester.pumpAndSettle();

      // Bottom bar updates to index 1
      final bottomNav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.currentIndex, equals(1));

      // PageView shows AqaidTab
      expect(find.text('AqaidTab'), findsOneWidget);
    });

    testWidgets('Horizontal drag swipe navigates smoothly between tabs and synchronizes bottom navigation bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestShellNavigation(),
        ),
      );
      await tester.pumpAndSettle();

      // Swipe left from HomeTab with fling
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      // Now at AqaidTab (index 1)
      expect(find.text('AqaidTab'), findsOneWidget);
      var bottomNav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.currentIndex, equals(1));

      // Swipe left again to MasailTab (index 2)
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('MasailTab'), findsOneWidget);
      bottomNav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.currentIndex, equals(2));

      // Swipe right back to AqaidTab (offset +400px)
      await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('AqaidTab'), findsOneWidget);
      bottomNav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.currentIndex, equals(1));
    });

    testWidgets('AutomaticKeepAlive preserves page state across horizontal swipes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestShellNavigation(),
        ),
      );
      await tester.pumpAndSettle();

      // Increment counter on HomeTab
      expect(find.text('Taps: 0'), findsOneWidget);
      await tester.tap(find.text('Increment'));
      await tester.pump();
      expect(find.text('Taps: 1'), findsOneWidget);

      // Swipe to AqaidTab (index 1)
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('AqaidTab'), findsOneWidget);

      // Swipe to MasailTab (index 2)
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('MasailTab'), findsOneWidget);

      // Swipe back all the way to HomeTab
      await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();
      await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();

      // State is preserved! Still Taps: 1
      expect(find.text('HomeTab'), findsOneWidget);
      expect(find.text('Taps: 1'), findsOneWidget);
    });
  });
}
