import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wokki_chat/theme/app_theme.dart';
import 'package:wokki_chat/services/server_service.dart';
import 'package:wokki_chat/services/auth_service.dart';
import 'package:wokki_chat/models/server_model.dart';

const _kLastServerId = 'last_server_id';
const _kLastChannelPrefix = 'last_channel_id_';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<ServerModel> _servers = [];
  bool _isLoading = false;
  ServerModel? _selectedServer;
  String? _selectedChannelId;
  final Set<String> _collapsedGroups = {};

  @override
  void initState() {
    super.initState();
    _loadServers();
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
    final prefs = await SharedPreferences.getInstance();
    if (serverId == null) {
      await prefs.remove(_kLastServerId);
    } else {
      await prefs.setString(_kLastServerId, serverId);
    }
  }

  Future<void> _saveLastChannelId(String serverId, String? channelId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_kLastChannelPrefix$serverId';
    if (channelId == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, channelId);
    }
  }

  Future<String?> _getLastServerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastServerId);
  }

  Future<String?> _getLastChannelId(String serverId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_kLastChannelPrefix$serverId');
  }

  String? _resolveChannelForServer(ServerModel server, String? lastChannelId) {
    final allChannels = server.channelGroups
        .expand((g) => g.channels)
        .toList();

    if (lastChannelId != null) {
      final match = allChannels.where((c) => c.id == lastChannelId).firstOrNull;
      if (match != null) return match.id;
    }

    final defaultChannel = allChannels.where((c) => c.isDefault == 1).firstOrNull;
    if (defaultChannel != null) return defaultChannel.id;

    return null;
  }

  Future<void> _loadServers() async {
    final cachedServers = await ServerService.loadCachedServers();

    if (cachedServers != null && cachedServers.isNotEmpty) {
      if (mounted) {
        final sorted = _sortedServers(cachedServers);
        await _applyInitialSelection(sorted);
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final token = await AuthService().getAccessToken();
      if (token != null) {
        final servers = await ServerService.fetchMyServers(token);
        if (mounted) {
          final sorted = _sortedServers(servers);
          setState(() => _isLoading = false);
          await _applyInitialSelection(sorted);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applyInitialSelection(List<ServerModel> sorted) async {
    if (!mounted) return;

    final lastServerId = await _getLastServerId();

    ServerModel? server;
    if (lastServerId != null) {
      server = sorted.where((s) => s.id == lastServerId).firstOrNull;
    }

    String? channelId;
    if (server != null) {
      final lastChannelId = await _getLastChannelId(server.id);
      channelId = _resolveChannelForServer(server, lastChannelId);
    }

    if (mounted) {
      setState(() {
        _servers = sorted;
        _selectedServer = server;
        _selectedChannelId = channelId;
      });
    }
  }

  void _onServerTap(ServerModel server) async {
    final lastChannelId = await _getLastChannelId(server.id);
    final channelId = _resolveChannelForServer(server, lastChannelId);

    await _saveLastServerId(server.id);

    if (mounted) {
      setState(() {
        _selectedServer = server;
        _selectedChannelId = channelId;
      });
    }
  }

  void _onChannelTap(String channelId) async {
    if (_selectedServer != null) {
      await _saveLastChannelId(_selectedServer!.id, channelId);
    }
    setState(() => _selectedChannelId = channelId);
  }

  void _onLogoTap() async {
    await _saveLastServerId(null);
    setState(() {
      _selectedServer = null;
      _selectedChannelId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeMode.slate.colors;

    return Scaffold(
      backgroundColor: colors.surfaceA0,
      body: Row(
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
                onToggleGroup: (groupId) {
                  setState(() {
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

  const _ChannelSidebar({
    required this.server,
    required this.colors,
    required this.collapsedGroups,
    required this.selectedChannelId,
    required this.sortedGroups,
    required this.sortedChannels,
    required this.onToggleGroup,
    required this.onChannelTap,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.surfaceA20, width: 1),
                ),
              ),
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