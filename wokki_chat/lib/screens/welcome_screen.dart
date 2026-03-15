import 'package:flutter/material.dart';
import 'package:wokki_chat/services/auth_service.dart';
import 'package:wokki_chat/services/api_service.dart';
import 'package:wokki_chat/theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  List<LastLoginInfo> _accounts = [];
  String? _loadingEmail;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await AuthService.getSavedAccounts();
    if (mounted) setState(() => _accounts = accounts);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'min' : 'mins'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${d == 1 ? 'day' : 'days'} ago';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Future<void> _tapAccount(LastLoginInfo info) async {
    if (info.email == null || info.email!.isEmpty) {
      Navigator.pushNamed(context, '/login', arguments: info.email);
      return;
    }

    final authService = AuthService();
    final savedRefresh = await authService.getRefreshTokenForAccount(info.email!);

    if (savedRefresh == null || savedRefresh.isEmpty) {
      if (mounted) Navigator.pushNamed(context, '/login', arguments: info.email);
      return;
    }

    if (mounted) setState(() => _loadingEmail = info.email);

    try {
      final response = await ApiService.refreshToken(savedRefresh);

      await authService.saveTokens(
        accessToken: response['access_token'],
        refreshToken: response['refresh_token'],
        expiresIn: (response['expires_in'] as num?)?.toInt() ?? 604800,
      );

      if (mounted) Navigator.pushReplacementNamed(context, '/setup');
    } catch (e) {
      await authService.deleteRefreshTokenForAccount(info.email!);
      if (mounted) {
        setState(() => _loadingEmail = null);
        Navigator.pushNamed(context, '/login', arguments: info.email);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeMode.slate.colors;

    return Scaffold(
      backgroundColor: colors.surfaceA0,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  'Wokki Chat',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: colors.textA0,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Connect with friends, share your world & make every conversation count.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: colors.textA40,
                    height: 1.4,
                  ),
                ),
              ),

              if (_accounts.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'PREVIOUS ACCOUNTS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textA40,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: colors.popupA0,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.popupA10, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        for (int i = 0; i < _accounts.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: colors.popupA10,
                              indent: 60,
                            ),
                          _AccountRow(
                            info: _accounts[i],
                            colors: colors,
                            timeAgo: _timeAgo(_accounts[i].time),
                            isLoading: _loadingEmail == _accounts[i].email,
                            onTap: _loadingEmail != null
                                ? null
                                : () => _tapAccount(_accounts[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              const Spacer(flex: 3),

              FilledButton(
                onPressed: _loadingEmail != null
                    ? null
                    : () => Navigator.pushNamed(context, '/login'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primaryA0,
                  disabledBackgroundColor: colors.primaryA0.withOpacity(0.5),
                  foregroundColor: colors.textWhiteA0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: colors.primaryA30, width: 1),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Log In'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadingEmail != null
                    ? null
                    : () => Navigator.pushNamed(context, '/signup'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primaryA0,
                  side: BorderSide(
                      color: colors.primaryA0.withOpacity(0.5), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final LastLoginInfo info;
  final dynamic colors;
  final String timeAgo;
  final bool isLoading;
  final VoidCallback? onTap;

  const _AccountRow({
    required this.info,
    required this.colors,
    required this.timeAgo,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = info.avatarUrl != null && info.avatarUrl!.isNotEmpty;
    final displayName = info.username ?? 'Unknown';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      splashColor: colors.primaryA0.withOpacity(0.08),
      highlightColor: colors.primaryA0.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: ClipOval(
                child: hasAvatar
                    ? Image.network(
                        info.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initial(initial, colors),
                      )
                    : _initial(initial, colors),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textA0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (info.email != null && info.email!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      info.email!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: colors.textA40,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primaryA0),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: colors.textA40,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: colors.textA40,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _initial(String initial, dynamic colors) {
    return Container(
      color: colors.surfaceA20,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textA20,
          ),
        ),
      ),
    );
  }
}