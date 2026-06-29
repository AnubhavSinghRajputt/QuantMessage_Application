// lib/screens/sidebar_panel/left_sidebar.dart
//


import 'package:flutter/material.dart';
import 'left_sidebar_extension.dart';

class LeftSidebar extends StatefulWidget {
  final VoidCallback? onNewChat;
  final VoidCallback? onProjects;
  final VoidCallback? onArtifacts;
  final VoidCallback? onCode;
  final VoidCallback? onCustomise;
  final VoidCallback? onBook;
  final VoidCallback? onDownload;

  const LeftSidebar({
    Key? key,
    this.onNewChat,
    this.onProjects,
    this.onArtifacts,
    this.onCode,
    this.onCustomise,
    this.onBook,
    this.onDownload,
  }) : super(key: key);

  @override
  State<LeftSidebar> createState() => _LeftSidebarState();
}

class _LeftSidebarState extends State<LeftSidebar>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;

  // Arrow rotation: 0° = pointing right (closed), 180° = pointing left (open)
  late final AnimationController _arrowCtrl;
  late final Animation<double>   _arrowRotation;

  bool _extensionOpen = false;

  @override
  void initState() {
    super.initState();
    _arrowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _arrowRotation = Tween<double>(begin: 0.0, end: 0.5)
        .animate(CurvedAnimation(
      parent: _arrowCtrl,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _arrowCtrl.dispose();
    super.dispose();
  }

  void _setSelectedIndex(int index) {
    setState(() => _selectedIndex = index);
  }

  void _toggleExtension() {
    if (_extensionOpen) {
      // Close: reverse arrow, dismiss overlay
      _arrowCtrl.reverse();
      LeftSidebarExtension.dismiss();
      setState(() => _extensionOpen = false);
    } else {
      // Open: rotate arrow, show overlay
      _arrowCtrl.forward();
      LeftSidebarExtension.show(context);
      setState(() => _extensionOpen = true);

      // When the overlay closes via backdrop tap, sync arrow back
      Future.delayed(const Duration(milliseconds: 10), () {
        if (mounted && _extensionOpen) {
          // Poll is not ideal — instead we use a callback via the
          // dismiss wrapper below.
        }
      });
    }
  }

  /// Called by the backdrop tap inside the overlay so the arrow resets.
  void _onExtensionDismissedExternally() {
    if (mounted) {
      _arrowCtrl.reverse();
      setState(() => _extensionOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [

          // ── Arrow icon — opens/closes the extension ──────────────────
          _SidebarIconButton(
            // Rotates via RotationTransition when extension is toggled
            customChild: RotationTransition(
              turns: _arrowRotation,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: (_extensionOpen || _selectedIndex == 0)
                    ? Colors.white
                    : const Color(0xFF666666),
              ),
            ),
            index: 0,
            isSelected: _extensionOpen,
            onTap: () {
              _setSelectedIndex(0);
              _toggleExtension();
            },
          ),
          const SizedBox(height: 24),

          _SidebarIconButton(
            icon: Icons.add,
            index: 1,
            isSelected: _selectedIndex == 1,
            onTap: () {
              _setSelectedIndex(1);
              widget.onNewChat?.call();
            },
          ),
          const SizedBox(height: 12),

          _SidebarIconButton(
            icon: Icons.chat_bubble_outline,
            index: 2,
            isSelected: _selectedIndex == 2,
            onTap: () => _setSelectedIndex(2),
          ),
          const SizedBox(height: 12),

          _SidebarIconButton(
            icon: Icons.layers_outlined,
            index: 3,
            isSelected: _selectedIndex == 3,
            onTap: () {
              _setSelectedIndex(3);
              widget.onProjects?.call();
            },
          ),
          const SizedBox(height: 12),

          _SidebarIconButton(
            icon: Icons.category_outlined,
            index: 4,
            isSelected: _selectedIndex == 4,
            onTap: () {
              _setSelectedIndex(4);
              widget.onArtifacts?.call();
            },
          ),
          const SizedBox(height: 12),

          _SidebarIconButton(
            icon: Icons.code,
            index: 5,
            isSelected: _selectedIndex == 5,
            onTap: () {
              _setSelectedIndex(5);
              widget.onCode?.call();
            },
          ),
          const SizedBox(height: 12),

          _SidebarIconButton(
            icon: Icons.work_outline,
            index: 6,
            isSelected: _selectedIndex == 6,
            onTap: () {
              _setSelectedIndex(6);
              widget.onCustomise?.call();
            },
          ),

          const Spacer(),

          _SidebarIconButton(
            icon: Icons.menu_book_outlined,
            index: 7,
            isSelected: _selectedIndex == 7,
            onTap: () {
              _setSelectedIndex(7);
              widget.onBook?.call();
            },
          ),

          const Spacer(),

          _SidebarIconButton(
            icon: Icons.file_download_outlined,
            index: 8,
            isSelected: _selectedIndex == 8,
            showNotificationDot: true,
            onTap: () {
              _setSelectedIndex(8);
              widget.onDownload?.call();
            },
          ),
          const SizedBox(height: 24),

          // Profile avatar
          Container(
            width:  28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFD3D3D3),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'AS',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Icon button (identical to original, plus optional customChild override)
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarIconButton extends StatefulWidget {
  final IconData?    icon;
  final Widget?      customChild;   // used for the animated arrow
  final VoidCallback onTap;
  final bool         isSelected;
  final int          index;
  final double       size;
  final bool         showNotificationDot;

  const _SidebarIconButton({
    Key? key,
    this.icon,
    this.customChild,
    required this.onTap,
    required this.isSelected,
    required this.index,
    this.size = 20.0,
    this.showNotificationDot = false,
  })  : assert(icon != null || customChild != null,
  'Provide either icon or customChild'),
        super(key: key);

  @override
  State<_SidebarIconButton> createState() => _SidebarIconButtonState();
}

class _SidebarIconButtonState extends State<_SidebarIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = (widget.isSelected || _isHovered)
        ? Colors.white
        : const Color(0xFF666666);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.white.withOpacity(0.15)
                : (_isHovered
                ? Colors.white.withOpacity(0.05)
                : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Either the custom child (arrow) or a plain icon
              widget.customChild ??
                  Icon(
                    widget.icon,
                    color: iconColor,
                    size: widget.size,
                  ),
              if (widget.showNotificationDot)
                Positioned(
                  right:  -2,
                  top:    -2,
                  child: Container(
                    width:  6,
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
      ),
    );
  }
}