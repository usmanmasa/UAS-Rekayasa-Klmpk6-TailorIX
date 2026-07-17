import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SafeNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const SafeNetworkImage({super.key, required this.url, this.width, this.height, this.fit});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (ctx, child, prog) {
        if (prog == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (ctx, err, st) => Container(
        width: width,
        height: height,
        color: AppColors.linen,
        child: const Center(child: Icon(Icons.broken_image, color: AppColors.charcoalSoft)),
      ),
    );
  }
}
