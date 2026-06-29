// lib/screens/sidebar_panel/left_sidebar_extension.dart

import 'dart:ui';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Public entry-point
// ─────────────────────────────────────────────────────────────────────────────

class LeftSidebarExtension {
  /// Width of the collapsed LeftSidebar — must match left_sidebar.dart.
  static const double sidebarWidth = 52.0;

  /// Width of the extension panel itself.
  static const double panelWidth = 260.0;

  static OverlayEntry? _entry;

  /// Inserts the extension into the Overlay.
  static void show(BuildContext context) {
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder: (_) => _SidebarExtensionOverlay(
        onClose: dismiss,
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  /// Removes the extension from the Overlay.
  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Overlay root — owns the AnimationController for the entire enter/exit
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarExtensionOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const _SidebarExtensionOverlay({required this.onClose});

  @override
  State<_SidebarExtensionOverlay> createState() =>
      _SidebarExtensionOverlayState();
}

class _SidebarExtensionOverlayState
    extends State<_SidebarExtensionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  /// Slide: panel enters from the left, offset by its own width.
  late final Animation<Offset> _slide;

  /// Blur + backdrop fade.
  late final Animation<double> _backdropOpacity;
  late final Animation<double> _blurAmount;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320), // ← slightly faster, smoother
    );

    // Smooth ease-out cubic — no overshoot bounce (cleaner, more professional)
    final easeCurve = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slide = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(easeCurve);

    _backdropOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(easeCurve);

    _blurAmount = Tween<double>(begin: 0.0, end: 8.0)
        .animate(easeCurve);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (!mounted) return;
    await _ctrl.reverse();
    if (!mounted) return;
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          children: [
            // ── Blurred backdrop ───────────────────────────────────────
            Positioned(
              left: LeftSidebarExtension.sidebarWidth,
              top: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: _close,
                behavior: HitTestBehavior.opaque,
                child: Opacity(
                  opacity: _backdropOpacity.value,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: _blurAmount.value,
                        sigmaY: _blurAmount.value,
                      ),
                      child: Container(color: Colors.black.withOpacity(0.42)),
                    ),
                  ),
                ),
              ),
            ),

            // ── Slide-in panel ─────────────────────────────────────────
            Positioned(
              left: LeftSidebarExtension.sidebarWidth,
              top: 0,
              bottom: 0,
              width: LeftSidebarExtension.panelWidth,
              child: SlideTransition(
                position: _slide,
                child: _ExtensionPanel(onClose: _close),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  The actual panel widget
// ─────────────────────────────────────────────────────────────────────────────

class _ExtensionPanel extends StatefulWidget {
  final Future<void> Function() onClose;
  const _ExtensionPanel({required this.onClose});

  @override
  State<_ExtensionPanel> createState() => _ExtensionPanelState();
}

class _ExtensionPanelState extends State<_ExtensionPanel> {
  // Recent chats data
  final List<_RecentChat> _recents = [
    _RecentChat('Integrating quantmessage_butt...', isActive: true),
    _RecentChat('Starting from scratch'),
    _RecentChat('Optimising splash screen animat...'),
    _RecentChat('Left sidebar extension implemen...'),
    _RecentChat('Integrating infinity animation int...'),
    _RecentChat('Apps and websites'),
    _RecentChat('Integrating animation effects int...'),
    _RecentChat('Smoothing animations and transi...'),
    _RecentChat('Responsive animation layout for...'),
    _RecentChat('iOS animation screen implement...'),
    _RecentChat('Creating documentation homes...'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F).withOpacity(0.92),
            border: Border(
              right: BorderSide(
                color: Colors.white.withOpacity(0.07),
                width: 0.5,
              ),
            ),
          ),
          // ← FIX: wrap in DefaultTextStyle with decoration: none
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              decoration: TextDecoration.none, // ← kills inherited underlines
              color: Colors.white,
            ),
            child: Column(
              children: [
                _buildHeader(),
                _buildNavItems(),
                _buildDivider(),
                _buildRecentsHeader(),
                Expanded(child: _buildRecentsList()),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Row(
        children: [
          // ← FIX: explicitly set decoration: TextDecoration.none
          const Expanded(
            child: Text(
              'QuantMessage',
              style: TextStyle(
                decoration: TextDecoration.none, // ← prevents double underline
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          _HeaderIconBtn(icon: Icons.search, onTap: () {}),
          const SizedBox(width: 2),
          _HeaderIconBtn(icon: Icons.space_dashboard_outlined, onTap: () {}),
        ],
      ),
    );
  }

  // ── Primary nav items ─────────────────────────────────────────────────────
  Widget _buildNavItems() {
    return Column(
      children: [
        _NavItem(icon: Icons.add, label: 'New chat', onTap: () {}),
        _NavItem(icon: Icons.chat_bubble_outline, label: 'Chats', onTap: () {}),
        _NavItem(icon: Icons.layers_outlined, label: 'Projects', onTap: () {}),
        _NavItem(icon: Icons.category_outlined, label: 'Artifacts', onTap: () {}),
        _NavItem(
          icon: Icons.code,
          label: 'Code',
          trailing: _UpgradeBadge(),
          onTap: () {},
        ),
        _NavItem(icon: Icons.work_outline, label: 'Customise', onTap: () {}),
      ],
    );
  }

  Widget _buildDivider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.white.withOpacity(0.07),
      indent: 16,
      endIndent: 16,
    ),
  );

  // ── Recents header ────────────────────────────────────────────────────────
  Widget _buildRecentsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
      child: Row(
        children: [
          // ← FIX: explicitly set decoration: TextDecoration.none
          Text(
            'Recents',
            style: TextStyle(
              decoration: TextDecoration.none, // ← prevents double underline
              color: Colors.white.withOpacity(0.40),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          _HeaderIconBtn(icon: Icons.tune, size: 16, onTap: () {}),
        ],
      ),
    );
  }

  // ── Scrollable recent chats ───────────────────────────────────────────────
  Widget _buildRecentsList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: _recents.length,
      itemBuilder: (context, index) {
        return _StaggeredFadeItem(
          delay: Duration(milliseconds: 60 + index * 28),
          child: _RecentChatItem(chat: _recents[index]),
        );
      },
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.07),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFD3D3D3),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'AS',
                style: TextStyle(
                  decoration: TextDecoration.none, // ← FIX
                  color: Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // ← FIX: explicitly set decoration: TextDecoration.none on both texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Anubhav Singh Rajput',
                  style: TextStyle(
                    decoration: TextDecoration.none, // ← FIX
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Free plan',
                  style: TextStyle(
                    decoration: TextDecoration.none, // ← FIX
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          _FooterIconBtn(
            icon: Icons.file_download_outlined,
            showDot: true,
            onTap: () {},
          ),
          const SizedBox(width: 2),
          _FooterIconBtn(icon: Icons.keyboard_arrow_up, onTap: () {}),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Reusable components — ALL text widgets include decoration: TextDecoration.none
// ═══════════════════════════════════════════════════════════════════════════

class _HeaderIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _HeaderIconBtn({
    required this.icon,
    required this.onTap,
    this.size = 18,
  });

  @override
  State<_HeaderIconBtn> createState() => _HeaderIconBtnState();
}

class _HeaderIconBtnState extends State<_HeaderIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.icon,
            size: widget.size,
            color: Colors.white.withOpacity(_hovered ? 0.90 : 0.50),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withOpacity(0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: Colors.white.withOpacity(_hovered ? 0.95 : 0.75),
              ),
              const SizedBox(width: 11),
              // ← FIX: explicitly set decoration: TextDecoration.none
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    decoration: TextDecoration.none, // ← FIX
                    color: Colors.white.withOpacity(_hovered ? 0.95 : 0.80),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _UpgradeBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
          width: 0.5,
        ),
      ),
      // ← FIX: explicitly set decoration: TextDecoration.none
      child: Text(
        'Upgrade',
        style: TextStyle(
          decoration: TextDecoration.none, // ← FIX
          color: Colors.white.withOpacity(0.70),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _RecentChat {
  final String title;
  final bool isActive;
  _RecentChat(this.title, {this.isActive = false});
}

class _RecentChatItem extends StatefulWidget {
  final _RecentChat chat;
  const _RecentChatItem({required this.chat});

  @override
  State<_RecentChatItem> createState() => _RecentChatItemState();
}

class _RecentChatItemState extends State<_RecentChatItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.chat.isActive;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withOpacity(0.09)
                : (_hovered
                ? Colors.white.withOpacity(0.05)
                : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // ← FIX: explicitly set decoration: TextDecoration.none
              Expanded(
                child: Text(
                  widget.chat.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    decoration: TextDecoration.none, // ← FIX
                    color: Colors.white.withOpacity(
                      active ? 0.95 : (_hovered ? 0.85 : 0.60),
                    ),
                    fontSize: 13.5,
                    fontWeight:
                    active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (_hovered)
                Icon(
                  Icons.more_horiz,
                  size: 16,
                  color: Colors.white.withOpacity(0.45),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  const _FooterIconBtn({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  @override
  State<_FooterIconBtn> createState() => _FooterIconBtnState();
}

class _FooterIconBtnState extends State<_FooterIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _hovered
                    ? Colors.white.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: Colors.white.withOpacity(_hovered ? 0.90 : 0.50),
              ),
            ),
            if (widget.showDot)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Staggered fade-in for list items ─────────────────────────────────────

class _StaggeredFadeItem extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _StaggeredFadeItem({
    required this.child,
    required this.delay,
  });

  @override
  State<_StaggeredFadeItem> createState() => _StaggeredFadeItemState();
}

class _StaggeredFadeItemState extends State<_StaggeredFadeItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(-0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
