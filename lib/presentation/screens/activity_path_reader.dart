import 'package:flutter/material.dart';

import '../../models/activity_path.dart';
import '../../widgets/gradient_background.dart';

class ActivityPathReaderPage extends StatefulWidget {
  final ActivityPath path;
  final ValueChanged<int>? onPageProgress;
  final VoidCallback? onCompleted;

  const ActivityPathReaderPage({
    super.key,
    required this.path,
    this.onPageProgress,
    this.onCompleted,
  });

  @override
  State<ActivityPathReaderPage> createState() => _ActivityPathReaderPageState();
}

class _ActivityPathReaderPageState extends State<ActivityPathReaderPage> {
  late final PageController _pageController;
  late int _currentPage;

  List<ActivityPathPage> get _pages => widget.path.pages;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.path.safeCurrentPageNumber - 1;
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.92,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPageProgress?.call(_currentPage + 1);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage >= _pages.length - 1) {
      widget.onCompleted?.call();
      Navigator.pop(context);
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _goBack() {
    if (_currentPage == 0) {
      Navigator.pop(context);
      return;
    }

    _pageController.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Image.asset('assets/images/back.png', height: 24, width: 24),
            onPressed: _goBack,
          ),
          title: Text(
            widget.path.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(
          child: _pages.isEmpty ? _emptyState() : _reader(),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'This activity path has no pages yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
      ),
    );
  }

  Widget _reader() {
    final progress = (_currentPage + 1) / _pages.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Page ${_currentPage + 1} of ${_pages.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF9FE7D3)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(
              parent: PageScrollPhysics(),
            ),
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              widget.onPageProgress?.call(index + 1);
            },
            itemBuilder: (_, index) => Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 5,
                right: index == _pages.length - 1 ? 0 : 5,
              ),
              child: _PathPageCard(page: _pages[index]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _goBack,
                  icon: _currentPage == 0
                      ? const Icon(Icons.close)
                      : Image.asset(
                          'assets/images/back.png',
                          height: 20,
                          width: 20,
                        ),
                  label: Text(_currentPage == 0 ? 'Close' : 'Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _goNext,
                  icon: Icon(
                    _currentPage == _pages.length - 1
                        ? Icons.check
                        : Icons.arrow_forward,
                  ),
                  label: Text(
                    _currentPage == _pages.length - 1 ? 'Finish' : 'Next',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF112650),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PathPageCard extends StatelessWidget {
  final ActivityPathPage page;

  const _PathPageCard({required this.page});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * 0.56,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6F1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Step ${page.pageNumber}',
                style: const TextStyle(
                  color: Color(0xFF16705D),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              page.title.isEmpty ? 'Untitled page' : page.title,
              style: const TextStyle(
                color: Color(0xFF10182E),
                fontSize: 24,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (page.images.isNotEmpty) ...[
              const SizedBox(height: 18),
              _PageImages(images: page.images),
            ],
            const SizedBox(height: 18),
            Text(
              page.body,
              style: const TextStyle(
                color: Color(0xFF2F3A4F),
                fontSize: 16,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageImages extends StatelessWidget {
  final List<ActivityPathImage> images;

  const _PageImages({required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return _ImageTile(
        imageUrl: images.first.imageUrl,
        height: 210,
        onTap: () => _openImage(context, images.first.imageUrl),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) => SizedBox(
          width: 210,
          child: _ImageTile(
            imageUrl: images[index].imageUrl,
            height: 150,
            onTap: () => _openImage(context, images[index].imageUrl),
          ),
        ),
      ),
    );
  }

  void _openImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(18),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Image unavailable',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String imageUrl;
  final double height;
  final VoidCallback onTap;

  const _ImageTile({
    required this.imageUrl,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF0F6),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Image.network(
          imageUrl,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => SizedBox(
            height: height,
            child: const Center(
              child: Icon(Icons.broken_image_outlined, color: Color(0xFF65738A)),
            ),
          ),
        ),
      ),
    );
  }
}
