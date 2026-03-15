import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wokki_chat/theme/app_theme.dart';
import 'package:wokki_chat/services/server_service.dart';
import 'package:wokki_chat/services/background_sync.dart';
import 'package:wokki_chat/services/auth_service.dart';
import 'package:wokki_chat/services/socket_service.dart';
import 'package:wokki_chat/models/server_model.dart';
import 'package:wokki_chat/state/chat_overlay_notifier.dart';
import 'package:wokki_chat/services/settings_service.dart';
import 'package:wokki_chat/theme/app_colors_provider.dart';

const _kLastServerId = 'last_server_id';
const _kLastChannelPrefix = 'last_channel_id_';
class HomeTab extends StatefulWidget {
  final ChatOverlayNotifier overlayNotifier;

  const HomeTab({super.key, required this.overlayNotifier});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<ServerModel> _servers = [];
  bool _isLoading = false;
  ServerModel? _selectedServer;
  String? _selectedChannelId;
  final Set<String> _collapsedGroups = {};
  bool _disposed = false;
  final _socketService = SocketService();
  String? _accessToken;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadServers();
    _initSocket();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) setState(fn);
  }

  Future<void> _initSocket() async {
    try {
      final authService = AuthService();
      final token = await authService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        _accessToken = token;
        _userId = await authService.getUserId();
        _socketService.connect(token);
      }
    } catch (_) {}
  }

  List<ServerModel> _sortedServers(List<ServerModel> servers) {
    final withPosition = servers.where((s) => s.position != null).toList()
      ..sort((a, b) => b.position!.compareTo(a.position!));
    final withoutPosition = servers.where((s) => s.position == null).toList();
    return [...withPosition, ...withoutPosition];
  }

  List<ChannelGroupModel> _sortedGroups(List<ChannelGroupModel> groups) {
    final withIndex = groups.where((g) => g.index != null).toList()
      ..sort((a, b) => b.index!.compareTo(a.index!));
    final withoutIndex = groups.where((g) => g.index == null).toList();
    return [...withIndex, ...withoutIndex];
  }

  List<ChannelModel> _sortedChannels(List<ChannelModel> channels) {
    final withIndex = channels.where((c) => c.index != null).toList()
      ..sort((a, b) => b.index!.compareTo(a.index!));
    final withoutIndex = channels.where((c) => c.index == null).toList();
    return [...withIndex, ...withoutIndex];
  }

  Future<void> _saveLastServerId(String? serverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (serverId == null) {
        await prefs.remove(_kLastServerId);
      } else {
        await prefs.setString(_kLastServerId, serverId);
      }
    } catch (_) {}
  }

  Future<void> _saveLastChannelId(String serverId, String? channelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_kLastChannelPrefix$serverId';
      if (channelId == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, channelId);
      }
    } catch (_) {}
  }

  Future<String?> _getLastServerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kLastServerId);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getLastChannelId(String serverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_kLastChannelPrefix$serverId');
    } catch (_) {
      return null;
    }
  }

  String? _resolveChannelForServer(ServerModel server, String? lastChannelId) {
    final allChannels = server.channelGroups.expand((g) => g.channels).toList();
    if (lastChannelId != null) {
      final match = allChannels.where((c) => c.id == lastChannelId).firstOrNull;
      if (match != null) return match.id;
    }
    final defaultChannel = allChannels.where((c) => c.isDefault == 1).firstOrNull;
    if (defaultChannel != null) return defaultChannel.id;
    return null;
  }

  ChannelModel? _findChannel(ServerModel server, String channelId) {
    for (final g in server.channelGroups) {
      for (final c in g.channels) {
        if (c.id == channelId) return c;
      }
    }
    return null;
  }

  Future<void> _loadServers() async {
    List<ServerModel>? cachedServers;
    try {
      cachedServers = await ServerService.loadCachedServers();
    } catch (_) {}

    if (cachedServers != null && cachedServers.isNotEmpty) {
      if (!_disposed && mounted) {
        final sorted = _sortedServers(cachedServers);
        await _applyInitialSelection(sorted);
      }
      _backgroundRefresh();
      return;
    }

    _safeSetState(() => _isLoading = true);

    try {
      final result = await BackgroundSync.run();
      if (_disposed) return;
      if (result.servers != null) {
        final sorted = _sortedServers(result.servers!);
        _safeSetState(() => _isLoading = false);
        await _applyInitialSelection(sorted);
      } else {
        _safeSetState(() => _isLoading = false);
      }
    } catch (_) {
      _safeSetState(() => _isLoading = false);
    }
  }

  Future<void> _backgroundRefresh() async {
    try {
      if (_disposed) return;
      final result = await BackgroundSync.run();
      if (_disposed) return;
      if (result.servers != null) {
        _applyBackgroundUpdate(_sortedServers(result.servers!));
      }
    } catch (_) {}
  }

  void _applyBackgroundUpdate(List<ServerModel> freshServers) {
    if (_disposed || !mounted) return;

    final currentServerId = _selectedServer?.id;
    final currentChannelId = _selectedChannelId;

    ServerModel? updatedSelectedServer;
    String? updatedChannelId = currentChannelId;

    if (currentServerId != null) {
      updatedSelectedServer =
          freshServers.where((s) => s.id == currentServerId).firstOrNull;

      if (updatedSelectedServer != null && currentChannelId != null) {
        final allChannels = updatedSelectedServer.channelGroups
            .expand((g) => g.channels)
            .toList();
        final channelStillExists =
            allChannels.any((c) => c.id == currentChannelId);
        if (!channelStillExists) {
          updatedChannelId =
              _resolveChannelForServer(updatedSelectedServer, null);
        }
      }
    }

    _safeSetState(() {
      _servers = freshServers;
      if (currentServerId != null && updatedSelectedServer == null) {
        _selectedServer = null;
        _selectedChannelId = null;
        _saveLastServerId(null);
      } else {
        _selectedServer = updatedSelectedServer;
        _selectedChannelId = updatedChannelId;
      }
    });
  }

  Future<void> _applyInitialSelection(List<ServerModel> sorted) async {
    if (_disposed || !mounted) return;

    final lastServerId = await _getLastServerId();
    if (_disposed || !mounted) return;

    ServerModel? server;
    if (lastServerId != null) {
      server = sorted.where((s) => s.id == lastServerId).firstOrNull;
    }

    String? channelId;

    if (server != null) {
      final lastChannelId = await _getLastChannelId(server.id);
      if (_disposed || !mounted) return;
      channelId = _resolveChannelForServer(server, lastChannelId);
    }

    _safeSetState(() {
      _servers = sorted;
      _selectedServer = server;
      _selectedChannelId = channelId;
    });
  }

  void _emitChangeRoom(String serverId, String channelId) {
    if (_accessToken != null) {
      _socketService.changeRoom(
        accessToken: _accessToken!,
        serverId: serverId,
        channelId: channelId,
      );
    }
  }

  void _openChat() {
    if (_selectedServer != null && _selectedChannelId != null && _userId != null) {
      widget.overlayNotifier.show(
        server: _selectedServer!.id,
        channel: _selectedChannelId!,
        userId: _userId!,
      );
    }
  }

  void _onServerTap(ServerModel server) async {
    final lastChannelId = await _getLastChannelId(server.id);
    if (_disposed || !mounted) return;

    String? channelId;

    if (SettingsService.autoOpenLastChannelNotifier.value) {
      channelId = _resolveChannelForServer(server, lastChannelId);
    }

    await _saveLastServerId(server.id);

    _safeSetState(() {
      _selectedServer = server;
      _selectedChannelId = channelId;
    });

    if (SettingsService.autoOpenLastChannelNotifier.value && channelId != null) {
      _emitChangeRoom(server.id, channelId);
      _openChat();
    }
  }

  void _onChannelTap(String channelId) async {
    if (_selectedServer != null) {
      await _saveLastChannelId(_selectedServer!.id, channelId);
      _emitChangeRoom(_selectedServer!.id, channelId);
    }
    _safeSetState(() => _selectedChannelId = channelId);
    _openChat();
  }

  void _onLogoTap() async {
    await _saveLastServerId(null);
    _safeSetState(() {
      _selectedServer = null;
      _selectedChannelId = null;
    });
    widget.overlayNotifier.hide();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsProvider.of(context);

    final hasChannelSelected = _selectedServer != null && _selectedChannelId != null;

    final sidebarContent = Row(
      children: [
        _ServerBar(
          servers: _servers,
          isLoading: _isLoading,
          selectedServer: _selectedServer,
          colors: colors,
          onServerTap: _onServerTap,
          onLogoTap: _onLogoTap,
        ),
        if (_selectedServer != null)
          Expanded(
            child: _ChannelSidebar(
              server: _selectedServer!,
              colors: colors,
              collapsedGroups: _collapsedGroups,
              selectedChannelId: _selectedChannelId,
              sortedGroups: _sortedGroups,
              sortedChannels: _sortedChannels,
              autoOpenLastChannel: SettingsService.autoOpenLastChannelNotifier.value,
              onAutoOpenChanged: (val) {
                SettingsService.setAutoOpenLastChannel(val);
              },
              onToggleGroup: (groupId) {
                _safeSetState(() {
                  if (_collapsedGroups.contains(groupId)) {
                    _collapsedGroups.remove(groupId);
                  } else {
                    _collapsedGroups.add(groupId);
                  }
                });
              },
              onChannelTap: _onChannelTap,
            ),
          )
        else
          Expanded(child: Container(color: colors.surfaceA0)),
      ],
    );

    return ListenableBuilder(
      listenable: SettingsService.autoOpenLastChannelNotifier,
      builder: (context, _) => Scaffold(
      backgroundColor: colors.surfaceA0,
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (!hasChannelSelected) return;
          final delta = details.delta.dx / MediaQuery.of(context).size.width;
          widget.overlayNotifier.updateDragValue(
              (widget.overlayNotifier.value.dragValue - delta).clamp(0.0, 1.0));
        },
        onHorizontalDragEnd: (details) {
          if (!hasChannelSelected) return;
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -300 || widget.overlayNotifier.value.dragValue > 0.5) {
            _openChat();
          } else {
            widget.overlayNotifier.hide();
          }
        },
        child: sidebarContent,
      ),
    ),
    );
  }
}

class _ServerBar extends StatelessWidget {
  final List<ServerModel> servers;
  final bool isLoading;
  final ServerModel? selectedServer;
  final dynamic colors;
  final ValueChanged<ServerModel> onServerTap;
  final VoidCallback onLogoTap;

  const _ServerBar({
    required this.servers,
    required this.isLoading,
    required this.selectedServer,
    required this.colors,
    required this.onServerTap,
    required this.onLogoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      color: colors.surfaceA0,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onLogoTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: double.infinity,
                        height: 45,
                        decoration: BoxDecoration(
                          color: selectedServer == null
                              ? colors.surfaceA10
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: selectedServer == null
                              ? Border.all(color: colors.surfaceA20, width: 1)
                              : null,
                        ),
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.asset(
                              'assets/icon/icon.png',
                              width: 45,
                              height: 45,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      if (selectedServer == null)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 3,
                            color: colors.primaryA0,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Divider(height: 1, thickness: 1, color: colors.surfaceA20),
            ),
            const SizedBox(height: 4),
            if (isLoading)
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colors.primaryA0),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: servers.length,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemBuilder: (context, index) {
                    final server = servers[index];
                    final isSelected = selectedServer?.id == server.id;
                    return GestureDetector(
                      onTap: () => onServerTap(server),
                      child: _ServerEntry(
                        server: server,
                        isSelected: isSelected,
                        colors: colors,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ServerEntry extends StatelessWidget {
  final ServerModel server;
  final bool isSelected;
  final dynamic colors;

  const _ServerEntry({
    required this.server,
    required this.isSelected,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              height: 45,
              decoration: BoxDecoration(
                color: isSelected ? colors.surfaceA10 : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(color: colors.surfaceA20, width: 1)
                    : null,
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                    width: 45,
                    height: 45,
                    child: server.image != null
                        ? Image.network(
                            server.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildInitial(server.name, colors),
                          )
                        : _buildInitial(server.name, colors),
                  ),
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: colors.primaryA0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitial(String name, dynamic colors) {
    return Container(
      color: colors.surfaceA20,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textA20,
          ),
        ),
      ),
    );
  }
}

class _ChannelSidebar extends StatelessWidget {
  final ServerModel server;
  final dynamic colors;
  final Set<String> collapsedGroups;
  final String? selectedChannelId;
  final List<ChannelGroupModel> Function(List<ChannelGroupModel>) sortedGroups;
  final List<ChannelModel> Function(List<ChannelModel>) sortedChannels;
  final ValueChanged<String> onToggleGroup;
  final ValueChanged<String> onChannelTap;
  final bool autoOpenLastChannel;
  final ValueChanged<bool> onAutoOpenChanged;

  const _ChannelSidebar({
    required this.server,
    required this.colors,
    required this.collapsedGroups,
    required this.selectedChannelId,
    required this.sortedGroups,
    required this.sortedChannels,
    required this.onToggleGroup,
    required this.onChannelTap,
    required this.autoOpenLastChannel,
    required this.onAutoOpenChanged,
  });

  @override
  Widget build(BuildContext context) {
    final groups = sortedGroups(server.channelGroups);

    return Container(
      decoration: BoxDecoration(
        color: colors.popupA0,
        border: Border(
          left: BorderSide(color: colors.popupA10, width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.surfaceA20, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          server.name,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.textA0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (server.description != null &&
                            server.description!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            server.description!,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: colors.textA40,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showSettings(context),
                    icon: Icon(
                      Icons.settings_rounded,
                      size: 18,
                      color: colors.textA40,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 6, bottom: 16),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final isCollapsed = collapsedGroups.contains(group.id);
                  final channels = sortedChannels(group.channels);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => onToggleGroup(group.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          child: Row(
                            children: [
                              AnimatedRotation(
                                turns: isCollapsed ? -0.25 : 0,
                                duration: const Duration(milliseconds: 150),
                                child: Icon(
                                  Icons.expand_more_rounded,
                                  size: 16,
                                  color: colors.textA40,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  group.name,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textA40,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isCollapsed)
                        ...channels.map(
                          (channel) => _ChannelItem(
                            channel: channel,
                            colors: colors,
                            isSelected: selectedChannelId == channel.id,
                            onTap: () => onChannelTap(channel.id),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.popupA0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        bool localValue = autoOpenLastChannel;
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Channel Settings',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textA0,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto-open last channel',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textA0,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Automatically open the last active channel when selecting a server',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: colors.textA40,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: localValue,
                      onChanged: (val) {
                        setSheetState(() => localValue = val);
                        onAutoOpenChanged(val);
                      },
                      activeColor: colors.primaryA0,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChannelItem extends StatelessWidget {
  final ChannelModel channel;
  final dynamic colors;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChannelItem({
    required this.channel,
    required this.colors,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.popupA10 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colors.popupA20 : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              channel.type == 'text'
                  ? Icons.tag_rounded
                  : Icons.volume_up_rounded,
              size: 18,
              color: isSelected ? colors.textA0 : colors.textA40,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                channel.name,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? colors.textA0 : colors.textA30,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}