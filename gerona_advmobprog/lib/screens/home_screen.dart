import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'product_screen.dart';
import 'chat_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import '../constants.dart';
import '../models/user.dart';
import '../providers/cart_provider.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class HomeScreen extends StatefulWidget {
  final User? user;
  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final UserService _userService = UserService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;

    if (_user != null) {
      _syncCartUser(_user!);
    } else {
      // Defensive fallback: HomeScreen should always be reached with a User (from Splash or Sign In), but if not, load it from the saved session.
      _userService.getUser().then((loadedUser) {
        if (!mounted) return;
        setState(() {
          _user = loadedUser;
        });
        _syncCartUser(loadedUser);
      });
    }
  }

  // LAB_ACT4 ENHANCEMENT 3:
  // Make sure the shared CartProvider always reflects whoever is signed in, whether we got here from the Sign In screen or straight from theSplash screen's persistent-auth check.
  void _syncCartUser(User user) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CartProvider>().configureForUser(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        // The Profile tab renders its own navy AppBar (with the user's first name + settings gear), so hide this shared one when active.
        appBar: _selectedIndex == 2
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                elevation: 2,
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                title: (_selectedIndex == 0)
                    ? Image.asset(
                        'assets/images/nubdexchange_logo.png',
                        scale: 11.sp,
                      )
                    : CustomText(
                        text: 'Cart',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      size: 24.sp,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: <Widget>[
            const ProductScreen(),
            const CartScreen(),
            _user != null
                ? ProfileScreen(user: _user!)
                : const Center(child: CircularProgressIndicator()),
          ],
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: _onTappedBar,
          selectedItemColor: AppColors.navy,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shop_2), label: 'Shop'),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
        ),
        // LAB_ACT2 ENHANCEMENT 2:
        // Changed the Chat bottom navigation into a FloatingActionButton. The Chat FloatingActionButton is hidden when the CartScreen is active.
        floatingActionButton: _selectedIndex == 1
            ? null
            : FloatingActionButton(
                tooltip: 'Chat',
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navy,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        userDisplayName: _user?.fullName.isNotEmpty == true
                            ? _user!.fullName
                            : _user?.username,
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.chat_outlined),
              ),
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
      _pageController.jumpToPage(value);
    });
  }
}
