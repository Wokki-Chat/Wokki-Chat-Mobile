import 'package:flutter/material.dart';
import 'package:wokki_chat/screens/tabs/home_tab.dart';
import 'package:wokki_chat/screens/tabs/notifications_tab.dart';
import 'package:wokki_chat/screens/tabs/profile_tab.dart';
import 'package:wokki_chat/screens/chat_screen.dart';
import 'package:wokki_chat/state/chat_overlay_notifier.dart';
import 'package:wokki_chat/theme/app_colors_provider.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with ThemeAware<HomeShell>, SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final ChatOverlayNotifier _overlayNotifier = ChatOverlayNotifier();

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.ease,
    ));

    _overlayNotifier.addListener(_onOverlayChanged);
  }

  @override
  void dispose() {
    _overlayNotifier.removeListener(_onOverlayChanged);
    _overlayNotifier.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onOverlayChanged() {
    final state = _overlayNotifier.value;
    if (state.visible) {
      _slideController.forward();
    } else if (state.dragValue > 0.0) {
      _slideController.value = state.dragValue;
    } else {
      _slideController.reverse();
    }
  }

  void _closeOverlay() {
    _overlayNotifier.hide();
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors;

    final tabs = [
      HomeTab(overlayNotifier: _overlayNotifier),
      const NotificationsTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: tabs,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceA10,
                  border: Border(
                    top: BorderSide(color: colors.surfaceA20, width: 1),
                  ),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                height: 60 + MediaQuery.of(context).padding.bottom,
                child: Row(
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      selected: _currentIndex == 0,
                      colors: colors,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                    _NavItem(
                      icon: Icons.notifications_rounded,
                      label: 'Notifications',
                      selected: _currentIndex == 1,
                      colors: colors,
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      selected: _currentIndex == 2,
                      colors: colors,
                      onTap: () => setState(() => _currentIndex = 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ValueListenableBuilder<ChatOverlayState>(
            valueListenable: _overlayNotifier,
            builder: (context, state, _) {
              if (state.server == null || state.channel == null) {
                return const SizedBox.shrink();
              }
              if (!state.visible && state.dragValue == 0.0) {
                return const SizedBox.shrink();
              }
              return GestureDetector(
                onHorizontalDragUpdate: (details) {
                  final delta = details.delta.dx / MediaQuery.of(context).size.width;
                  final newVal = (_slideController.value - delta).clamp(0.0, 1.0);
                  _slideController.value = newVal;
                },
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity > 300 || _slideController.value < 0.5) {
                    _closeOverlay();
                  } else {
                    _slideController.forward();
                  }
                },
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ChatScreen(
                    server: state.server!,
                    channel: state.channel!,
                    onShowSidebar: _closeOverlay,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final dynamic colors;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? colors.primaryA0.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 24,
                color: selected ? colors.primaryA0 : colors.textA40,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? colors.primaryA0 : colors.textA40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}