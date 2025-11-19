import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppScaffold extends StatefulWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget body;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClosed;
  final String? searchHint;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AppScaffold({
    super.key,
    this.title,
    this.actions,
    required this.body,
    this.searchController,
    this.onSearchChanged,
    this.onSearchClosed,
    this.searchHint,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _isSearchActive = false;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (_isSearchActive) {
        _searchFocusNode.requestFocus();
      } else {
        _searchFocusNode.unfocus();
        widget.searchController?.clear();
        widget.onSearchClosed?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    // Build actions list - search button at the end (rightmost)
    final List<Widget> effectiveActions = [
      ...?widget.actions,
      if (widget.searchController != null && !_isSearchActive)
        IconButton(
          icon: Icon(PhosphorIconsRegular.magnifyingGlass, size: 20),
          onPressed: _toggleSearch,
        ),
    ];

    // Determine if header should be shown
    final bool hasHeader = widget.title != null || effectiveActions.isNotEmpty;

    // When there's no header, use Scaffold with SafeArea only for top
    if (!hasHeader) {
      return Scaffold(
        backgroundColor: theme.colors.background,
        body: SafeArea(
          bottom: false, // Allow bottom content to extend to edge (for bottom nav)
          child: widget.body,
        ),
        floatingActionButton: widget.floatingActionButton,
        floatingActionButtonLocation: widget.floatingActionButtonLocation,
      );
    }

    // When there's a header, use Scaffold with FHeader
    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Stack(
              children: [
                // Standard Header
                Opacity(
                  opacity: _isSearchActive ? 0.0 : 1.0,
                  child: FHeader(
                    title: widget.title ?? const SizedBox.shrink(),
                    suffixes: effectiveActions,
                  ),
                ),

                // Search Overlay
                if (_isSearchActive && widget.searchController != null)
                  Positioned.fill(
                    child: Container(
                      color: theme.colors.background,
                      child: Container(
                        height: 56, // Match FHeader height roughly
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            Expanded(
                              child: FTextField(
                                controller: widget.searchController,
                                focusNode: _searchFocusNode,
                                onChange: widget.onSearchChanged,
                                hint: widget.searchHint ?? '검색...',
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(PhosphorIconsRegular.x, size: 20),
                                onPressed: _toggleSearch,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(child: widget.body),
          ],
        ),
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }
}
