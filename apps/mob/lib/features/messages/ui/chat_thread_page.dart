import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/design_tokens.dart';
import 'data/chat_models.dart';

class ChatThreadPage extends StatefulWidget {
  final ChatThread thread;
  const ChatThreadPage({super.key, required this.thread});

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  final FocusNode _inputFocus = FocusNode();

  late List<ChatMessage> _messages;
  final Set<String> _selected = {};

  bool get _selecting => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messages = List<ChatMessage>.from(widget.thread.messages);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  // --- Senders ---
  void _sendText() {
    final txt = _controller.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        sender: 'You',
        avatarUrl: '',
        isMe: true,
        kind: MessageKind.text,
        text: txt,
      ));
      _controller.clear();
    });
    _scrollToEnd();
  }

  Future<void> _sendImage({required bool camera}) async {
    try {
      final XFile? file = camera
          ? await _picker.pickImage(source: ImageSource.camera)
          : await _picker.pickImage(source: ImageSource.gallery);
      if (!mounted || file == null) return;
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          sender: 'You',
          avatarUrl: '',
          isMe: true,
          kind: MessageKind.image,
          mediaPath: file.path,
        ));
      });
      _scrollToEnd();
    } catch (_) {}
  }

  Future<void> _sendVideo() async {
    try {
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
      if (!mounted || file == null) return;
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          sender: 'You',
          avatarUrl: '',
          isMe: true,
          kind: MessageKind.video,
          mediaPath: file.path,
        ));
      });
      _scrollToEnd();
    } catch (_) {}
  }

  Future<void> _sendLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          sender: 'You',
          avatarUrl: '',
          isMe: true,
          kind: MessageKind.location,
          location: GeoPoint(pos.latitude, pos.longitude),
        ));
      });
      _scrollToEnd();
    } catch (_) {}
  }

  // --- Selection / delete ---
  void _toggleSelect(String id) {
    setState(() => _selected.contains(id)
        ? _selected.remove(id)
        : _selected.add(id));
  }

  void _deleteSelected() {
    setState(() {
      _messages.removeWhere((m) => _selected.contains(m.id));
      _selected.clear();
    });
  }

  Future<void> _openAttachSheet() async {
    _inputFocus.unfocus();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(DT.s.lg),
          child: Wrap(
            runSpacing: 8,
            children: [
              _AttachTile(
                  icon: Icons.photo_outlined,
                  label: 'Photo (Gallery)',
                  onTap: () {
                    Navigator.pop(context);
                    _sendImage(camera: false);
                  }),
              _AttachTile(
                  icon: Icons.photo_camera_outlined,
                  label: 'Photo (Camera)',
                  onTap: () {
                    Navigator.pop(context);
                    _sendImage(camera: true);
                  }),
              _AttachTile(
                  icon: Icons.videocam_outlined,
                  label: 'Video',
                  onTap: () {
                    Navigator.pop(context);
                    _sendVideo();
                  }),
              _AttachTile(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  onTap: () {
                    Navigator.pop(context);
                    _sendLocation();
                  }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.thread;
    final insets = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: DT.c.surface,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon:
              Icon(_selecting ? Icons.close_rounded : Icons.arrow_back_rounded),
          onPressed: () =>
              _selecting ? setState(_selected.clear) : Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(t.name, style: DT.t.h1.copyWith(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              t.online
                  ? 'Online'
                  : t.lastSeen != null
                      ? 'Last seen ${_ago(t.lastSeen!)}'
                      : '',
              style: DT.t.label.copyWith(color: DT.c.textMuted),
            ),
          ],
        ),
        actions: _selecting
            ? [
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _deleteSelected,
                )
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: () {},
                )
              ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(DT.s.lg, DT.s.sm, DT.s.lg, DT.s.md),
            child: Text(
              'System message: Your personal details are hidden until you explicitly share them.',
              textAlign: TextAlign.center,
              style: DT.t.body.copyWith(color: DT.c.textMuted),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isMe = m.isMe;
                final selected = _selected.contains(m.id);

                return GestureDetector(
                  onLongPress: () => _toggleSelect(m.id),
                  onTap: () => _selecting ? _toggleSelect(m.id) : null,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: DT.s.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isMe)
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFE6EAF2),
                            child: Text(m.sender.characters.first),
                          ),
                        if (!isMe) SizedBox(width: DT.s.sm),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(m.sender,
                                  style:
                                      DT.t.body.copyWith(color: DT.c.brand)),
                              const SizedBox(height: 6),
                              Container(
                                padding: EdgeInsets.all(DT.s.lg),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? DT.c.brand
                                      : DT.c.blueTint
                                          .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft:
                                        Radius.circular(isMe ? 16 : 4),
                                    bottomRight:
                                        Radius.circular(isMe ? 4 : 16),
                                  ),
                                  border: selected
                                      ? Border.all(
                                          color: DT.c.brand, width: 1.2)
                                      : null,
                                ),
                                child: _Bubble(msg: m, isMe: isMe),
                              ),
                            ],
                          ),
                        ),
                        if (isMe) SizedBox(width: DT.s.sm),
                        if (isMe)
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFE6EAF2),
                            child: Icon(Icons.person),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Quick actions
          Padding(
            padding: EdgeInsets.fromLTRB(DT.s.lg, 0, DT.s.lg, DT.s.sm),
            child: Column(
              children: const [
                _QuickAction(
                    icon: Icons.help_outline_rounded,
                    label: 'Ask about unique mark'),
                SizedBox(height: 12),
                _QuickAction(
                    icon: Icons.image_outlined,
                    label: 'Request extra photo'),
              ],
            ),
          ),
          // Input
          AnimatedPadding(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: insets > 0 ? insets : 0),
            child: SafeArea(
              top: false,
              minimum:
                  EdgeInsets.fromLTRB(DT.s.lg, 0, DT.s.lg, DT.s.lg),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Attach',
                    onPressed: _openAttachSheet,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                  Expanded(
                    child: Container(
                      height: 56,
                      padding:
                          EdgeInsets.symmetric(horizontal: DT.s.lg),
                      decoration: BoxDecoration(
                        color: DT.c.blueTint
                            .withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              focusNode: _inputFocus,
                              controller: _controller,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendText(),
                              minLines: 1,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                  hintText: 'Write a message...',
                                  border: InputBorder.none),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: DT.s.md),
                  FilledButton(
                    onPressed: _sendText,
                    style: FilledButton.styleFrom(
                      backgroundColor: DT.c.brand,
                      minimumSize: const Size(56, 56),
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  const _Bubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    switch (msg.kind) {
      case MessageKind.text:
        return Text(
          msg.text ?? '',
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(
                  color: isMe ? Colors.white : DT.c.text, height: 1.5),
        );
      case MessageKind.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: msg.mediaPath != null
              ? Image.file(File(msg.mediaPath!), height: 180)
              : const SizedBox(),
        );
      case MessageKind.video:
        return Container(
          height: 120,
          width: 220,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.play_circle_fill_rounded,
                  size: 36, color: Colors.white),
              SizedBox(width: 8),
              Text('Video', style: TextStyle(color: Colors.white)),
            ],
          ),
        );
      case MessageKind.location:
        final p = msg.location!;
        return InkWell(
          onTap: () => _openMaps(p),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded,
                  color: isMe ? Colors.white : DT.c.brand),
              const SizedBox(width: 8),
              Text(
                '${p.lat.toStringAsFixed(5)}, ${p.lng.toStringAsFixed(5)}',
                style:
                    TextStyle(color: isMe ? Colors.white : DT.c.text),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded,
                  size: 18, color: isMe ? Colors.white : DT.c.brand),
            ],
          ),
        );
    }
  }

  Future<void> _openMaps(GeoPoint p) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${p.lat},${p.lng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
            radius: 22,
            backgroundColor:
                DT.c.blueTint.withValues(alpha: 0.6),
            child: Icon(icon, color: DT.c.text)),
        SizedBox(width: DT.s.md),
        Text(label, style: DT.t.body),
      ],
    );
  }
}

class _AttachTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AttachTile(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: Icon(icon, color: DT.c.brand),
        title: Text(label),
        onTap: onTap);
  }
}

String _ago(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
