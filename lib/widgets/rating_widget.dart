import 'package:flutter/material.dart';

class RatingWidget extends StatefulWidget {
  final double initialRating;
  final bool isReadOnly;
  final Function(double)? onRatingChanged;
  final Function(String)? onReviewChanged;
  final String? initialReview;
  final bool showReviewField;
  final String? title;

  const RatingWidget({
    Key? key,
    this.initialRating = 0.0,
    this.isReadOnly = false,
    this.onRatingChanged,
    this.onReviewChanged,
    this.initialReview,
    this.showReviewField = true,
    this.title,
  }) : super(key: key);

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  late double _rating;
  late TextEditingController _reviewController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _reviewController = TextEditingController(text: widget.initialReview ?? '');
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Star rating
        Row(
          children: [
            // Stars
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: widget.isReadOnly ? null : () => _updateRating(index + 1.0),
                  child: Icon(
                    index < _rating.floor() 
                        ? Icons.star 
                        : (index < _rating ? Icons.star_half : Icons.star_border),
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(width: 12),
            
            // Rating text
            Text(
              '${_rating.toStringAsFixed(1)}/5.0',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        // Rating categories (for detailed ratings)
        if (!widget.isReadOnly && _isExpanded) ...[
          const SizedBox(height: 16),
          _buildRatingCategories(),
        ],

        // Review field
        if (widget.showReviewField) ...[
          const SizedBox(height: 16),
          _buildReviewField(),
        ],

        // Expand/collapse button for detailed ratings
        if (!widget.isReadOnly) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Text(
              _isExpanded ? 'Hide Details' : 'Add Detailed Rating',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRatingCategories() {
    final categories = [
      {'name': 'Punctuality', 'icon': Icons.schedule},
      {'name': 'Professionalism', 'icon': Icons.work},
      {'name': 'Care Quality', 'icon': Icons.favorite},
      {'name': 'Communication', 'icon': Icons.chat},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate by Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...categories.map((category) => _buildCategoryRating(category)),
      ],
    );
  }

  Widget _buildCategoryRating(Map<String, dynamic> category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            category['icon'] as IconData,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category['name'] as String,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  // TODO: Implement category-specific ratings
                },
                child: Icon(
                  Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reviewController,
          enabled: !widget.isReadOnly,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: widget.isReadOnly 
                ? 'No review provided'
                : 'Share your experience with this caregiver...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: widget.isReadOnly,
            fillColor: widget.isReadOnly ? Colors.grey[100] : null,
          ),
          onChanged: widget.onReviewChanged,
        ),
      ],
    );
  }

  void _updateRating(double newRating) {
    setState(() {
      _rating = newRating;
    });
    widget.onRatingChanged?.call(newRating);
  }
}

// Compact rating display for cards
class CompactRatingDisplay extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final bool showReviewCount;

  const CompactRatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount = 0,
    this.showReviewCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Stars
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < rating.floor() 
                  ? Icons.star 
                  : (index < rating ? Icons.star_half : Icons.star_border),
              color: Colors.amber,
              size: 16,
            );
          }),
        ),
        const SizedBox(width: 4),
        
        // Rating text
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // Review count
        if (showReviewCount && reviewCount > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}

// Rating bar for statistics
class RatingBar extends StatelessWidget {
  final double rating;
  final double maxRating;
  final double height;
  final Color color;

  const RatingBar({
    Key? key,
    required this.rating,
    this.maxRating = 5.0,
    this.height = 8,
    this.color = Colors.amber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = rating / maxRating;
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

// Rating statistics widget
class RatingStatistics extends StatelessWidget {
  final Map<int, int> ratingDistribution; // rating -> count
  final double averageRating;
  final int totalReviews;

  const RatingStatistics({
    super.key,
    required this.ratingDistribution,
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Average rating
        Row(
          children: [
            Text(
              averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < averageRating.floor() 
                          ? Icons.star 
                          : (index < averageRating ? Icons.star_half : Icons.star_border),
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
                Text(
                  '$totalReviews reviews',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Rating distribution
        ...List.generate(5, (index) {
          final rating = 5 - index;
          final count = ratingDistribution[rating] ?? 0;
          final percentage = totalReviews > 0 ? count / totalReviews : 0.0;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(
                  '$rating',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RatingBar(
                    rating: percentage * 5,
                    height: 6,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
} 