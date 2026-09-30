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
  // Lab Activity 6 (Additional Instructions):
  // The second BottomNavigationTab is now Chat (previously only reachable
  // via the floating "Chat" button), so tabs are: Shop, Chat, Cart, Profile.
  static const int _shopIndex = 0;
  static const int _chatIndex = 1;
  static const int _cartIndex = 2;
  static const int _profileIndex = 3;

  int _selectedIndex = _shopIndex;
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
      // Defensive fallback: HomeScreen should always be reached with a User
      // (from Splash or Sign In), but if not, load it from the saved session.
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
  // Make sure the shared CartProvider always reflects whoever is signed in.
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
        // The Profile tab renders its own navy AppBar, so hide this shared
        // one when active.
        appBar: _selectedIndex == _profileIndex
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                elevation: 2,
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                title: _appBarTitle(),
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings, size: 24.sp, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: <Widget>[
            const ProductScreen(),
            // Lab Activity 6 (Additional Instructions):
            // Applied the Chat List UI here, replacing the old floating
            // "Chat" button flow.
            const ChatScreen(),
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
          // Keep the bar and every tab icon visible in both themes. The
          // selected icon uses the app's navy, while inactive icons use the
          // theme's contrasting surface color.
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: _onTappedBar,
          selectedItemColor: AppColors.navy,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          selectedIconTheme: const IconThemeData(size: 24),
          unselectedIconTheme: const IconThemeData(size: 24),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shop_2), label: 'Shop'),
            // Lab Activity 6 (Additional Instructions): changed icon.
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
        ),
      ),
    );
  }

  Widget _appBarTitle() {
    switch (_selectedIndex) {
      case _shopIndex:
        return Image.asset(
          'assets/images/nubdexchange_logo.png',
          scale: 11.sp,
        );
      case _chatIndex:
        return CustomText(
          text: 'Messages',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );
      case _cartIndex:
        return CustomText(
          text: 'Cart',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
      _pageController.jumpToPage(value);
    });
  }
}
