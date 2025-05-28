import 'package:flutter/material.dart';
import '../ui/app_colors.dart';

typedef ImageTapCallback = void Function(int index);

class ImageCarouselWithFavorite extends StatefulWidget {
  final List<String> images;
  final bool isFavorite;
  final bool isLoading;
  final VoidCallback onToggleFavorite;
  final ImageTapCallback onImageTap;

  const ImageCarouselWithFavorite({
    Key? key,
    required this.images,
    required this.isFavorite,
    required this.isLoading,
    required this.onToggleFavorite,
    required this.onImageTap,
  }) : super(key: key);

  @override
  _ImageCarouselWithFavoriteState createState() =>
      _ImageCarouselWithFavoriteState();
}

class _ImageCarouselWithFavoriteState extends State<ImageCarouselWithFavorite> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final imageUrl = widget.images[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => widget.onImageTap(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
          ),
          Positioned(
            top: 16,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onToggleFavorite,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color.fromARGB(255, 255, 0, 0)),
                          ),
                        )
                      : Icon(
                          widget.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.isFavorite
                              ? Colors.red.shade500
                              : AppColors.textSecondary,
                          size: 24,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
