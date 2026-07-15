import 'package:flutter/material.dart';

import '../../controllers/activity_path_controller.dart';
import '../../models/activity_path.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gradient_background.dart';
import 'activity_path_reader.dart';
import 'login.dart';

class ActivityMainPage extends StatefulWidget {
  const ActivityMainPage({super.key});

  @override
  State<ActivityMainPage> createState() => _ActivityMainPageState();
}

class _ActivityMainPageState extends State<ActivityMainPage> {
  final ActivityPathController _pathController = ActivityPathController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pathController.addListener(_refresh);
    _searchController.addListener(_handleSearchChanged);
    _pathController.loadPaths();
  }

  @override
  void dispose() {
    _pathController.removeListener(_refresh);
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _handleSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _refreshAll() async {
    await _pathController.loadPaths();
  }

  Future<void> _openPath(ActivityPath path) async {
    try {
      await _pathController.selectPath(path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start this activity path.')),
      );
      return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityPathReaderPage(
          path: path,
          onPageProgress: (pageNumber) {
            _pathController.updateProgress(
              path: path,
              currentPageNumber: pageNumber,
              completedPageCount: pageNumber > path.completedPageCount
                  ? pageNumber
                  : path.completedPageCount,
              isCompleted: pageNumber >= path.pages.length,
            );
          },
          onCompleted: () {
            _pathController.updateProgress(
              path: path,
              currentPageNumber: path.pages.isEmpty ? 1 : path.pages.length,
              completedPageCount: path.pages.length,
              isCompleted: true,
            );
          },
        ),
      ),
    );
    await _pathController.loadPaths();
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return DefaultTabController(
      length: 3,
      child: GradientBackground(
        child: MainTabEdgeSwipeZones(
          currentIndex: 3,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await authService.signOut();

                    if (!context.mounted) return;

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                ),
              ],
            ),
            bottomNavigationBar: const BottomNavBar(currentIndex: 3),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose a Guided Path',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Follow short pages at your own pace, with images and reflection prompts prepared by the team.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color(0xFF9FE7D3),
                      decoration: InputDecoration(
                        hintText: 'Search paths',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.52),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white70,
                        ),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: _searchController.clear,
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                ),
                              ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF9FE7D3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelColor: const Color(0xFF10182E),
                        unselectedLabelColor: Colors.white,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        tabs: const [
                          Tab(text: 'All Paths'),
                          Tab(text: 'My Paths'),
                          Tab(text: 'Saved'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: TabBarView(
                      physics: const BouncingScrollPhysics(
                        parent: PageScrollPhysics(),
                      ),
                      children: [
                        _buildPathBody(_filteredPaths(_pathController.paths)),
                        _buildMyPathBody(),
                        _buildSavedPathBody(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPathBody(List<ActivityPath> paths) {
    if (_pathController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pathController.errorMessage != null) {
      return _messageState(
        icon: Icons.error_outline,
        title: 'Paths unavailable',
        message: _pathController.errorMessage!,
        actionLabel: 'Try again',
        onAction: _pathController.loadPaths,
      );
    }

    if (paths.isEmpty) {
      return _messageState(
        icon: Icons.route_outlined,
        title: 'No active paths yet',
        message: 'New guided activity paths will appear here when available.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: paths.length,
        itemBuilder: (_, index) => _buildPathCard(paths[index]),
      ),
    );
  }

  Widget _buildMyPathBody() {
    if (_pathController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pathController.errorMessage != null) {
      return _messageState(
        icon: Icons.error_outline,
        title: 'Paths unavailable',
        message: _pathController.errorMessage!,
        actionLabel: 'Try again',
        onAction: _pathController.loadPaths,
      );
    }

    final selectedPaths = _filteredPaths(_pathController.selectedPaths);

    if (selectedPaths.isEmpty) {
      return _messageState(
        icon: Icons.bookmark_border,
        title: 'No selected paths yet',
        message: _searchQuery.isEmpty
            ? 'Start a path from All Paths and it will appear here.'
            : 'No started paths match your search.',
      );
    }

    return _buildPathBody(selectedPaths);
  }

  Widget _buildSavedPathBody() {
    if (_pathController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pathController.errorMessage != null) {
      return _messageState(
        icon: Icons.error_outline,
        title: 'Paths unavailable',
        message: _pathController.errorMessage!,
        actionLabel: 'Try again',
        onAction: _pathController.loadPaths,
      );
    }

    final savedPaths = _filteredPaths(_pathController.savedPaths);

    if (savedPaths.isEmpty) {
      return _messageState(
        icon: Icons.bookmark_border,
        title: 'No saved paths yet',
        message: _searchQuery.isEmpty
            ? 'Tap the bookmark on any path to save it for later.'
            : 'No saved paths match your search.',
      );
    }

    return _buildPathBody(savedPaths);
  }

  List<ActivityPath> _filteredPaths(List<ActivityPath> paths) {
    if (_searchQuery.isEmpty) return paths;

    return paths.where((path) {
      final pageText = path.pages
          .map((page) => '${page.title} ${page.body}')
          .join(' ')
          .toLowerCase();
      final searchable = [
        path.title,
        path.description ?? '',
        pageText,
      ].join(' ').toLowerCase();

      return searchable.contains(_searchQuery);
    }).toList();
  }

  Widget _buildPathCard(ActivityPath path) {
    final firstImage = path.coverImageUrl?.isNotEmpty == true
        ? path.coverImageUrl
        : path.pages
              .expand((page) => page.images)
              .map((image) => image.imageUrl)
              .cast<String?>()
              .firstWhere(
                (url) => url != null && url.isNotEmpty,
                orElse: () => null,
              );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openPath(path),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (firstImage != null)
                Image.network(
                  firstImage,
                  width: double.infinity,
                  height: 156,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                )
              else
                Container(
                  width: double.infinity,
                  height: 118,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF9FE7D3).withValues(alpha: 0.35),
                        const Color(0xFFB9C7FF).withValues(alpha: 0.22),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.route_outlined,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${path.pages.length} page${path.pages.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (path.isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9FE7D3),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              path.isCompleted ? 'Completed' : 'Started',
                              style: const TextStyle(
                                color: Color(0xFF10251F),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: path.isSaved ? 'Unsave path' : 'Save path',
                          onPressed: () => _toggleSaved(path),
                          icon: Icon(
                            path.isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: path.isSaved
                                ? const Color(0xFF9FE7D3)
                                : Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white.withValues(alpha: 0.82),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      path.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (path.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        path.description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          height: 1.35,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (path.isSelected) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: path.progressFraction,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF9FE7D3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(path.progressFraction * 100).round()}% completed',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _openPath(path),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF112650),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          path.isSelected ? 'Continue Path' : 'Start Path',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, height: 1.35),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSaved(ActivityPath path) async {
    try {
      await _pathController.setSaved(path, !path.isSaved);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path.isSaved
                ? 'Unable to remove saved path.'
                : 'Unable to save path.',
          ),
        ),
      );
    }
  }
}
