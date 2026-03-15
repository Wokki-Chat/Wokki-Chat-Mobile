import 'package:flutter/material.dart';
import 'package:wokki_chat/theme/app_theme.dart';
import 'package:wokki_chat/services/server_service.dart';
import 'package:wokki_chat/services/auth_service.dart';
import 'package:wokki_chat/models/server_model.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<ServerModel> _servers = [];
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  Future<void> _loadServers() async {
    final cachedServers = await ServerService.loadCachedServers();
    
    if (cachedServers != null && cachedServers.isNotEmpty) {
      if (mounted) {
        setState(() => _servers = cachedServers);
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final token = await AuthService().getAccessToken();
      if (token != null) {
        final servers = await ServerService.fetchMyServers(token);
        if (mounted) {
          setState(() {
            _servers = servers;
            _isLoading = false;
            _hasError = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeMode.slate.colors;

    return Scaffold(
      backgroundColor: colors.surfaceA0,
      body: Row(
        children: [
          Container(
            width: 70,
            decoration: BoxDecoration(
              color: colors.surfaceA0,
            ),
            child: SafeArea(
              child: _isLoading
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(colors.primaryA0),
                        ),
                      ),
                    )
                  : _servers.isEmpty
                      ? const SizedBox()
                      : ListView.builder(
                          itemCount: _servers.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final server = _servers[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 6),
                              child: GestureDetector(
                                onTap: () {},
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: colors.surfaceA20,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: server.image != null
                                        ? Image.network(
                                            server.image!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _buildServerInitial(
                                                    server.name, colors),
                                          )
                                        : _buildServerInitial(
                                            server.name, colors),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: colors.surfaceA0,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 64, color: colors.textA40),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: colors.textA10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Start a conversation to get going.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: colors.textA40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerInitial(String name, dynamic colors) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
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