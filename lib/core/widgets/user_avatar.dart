import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final double radius;
  final String? profileImageBase64;
  final String? photoUrl;
  final String? displayName;
  final bool showEditButton;
  final VoidCallback? onEditPressed;
  final bool isLoading;

  const UserAvatar({
    super.key,
    this.radius = 36,
    this.profileImageBase64,
    this.photoUrl,
    this.displayName,
    this.showEditButton = false,
    this.onEditPressed,
    this.isLoading = false,
  });

  Uint8List? _decodeBase64(String? base64String) {
    if (base64String == null || base64String.trim().isEmpty) return null;
    try {
      // Remove data URI prefix if present (e.g., 'data:image/jpeg;base64,')
      final cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last.trim()
          : base64String.trim();
      return base64Decode(cleanBase64);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (displayName != null && displayName!.trim().isNotEmpty)
        ? displayName!.trim()
        : 'U';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    final base64Bytes = _decodeBase64(profileImageBase64);

    final avatarContent = ClipOval(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: AppColors.emeraldDeep.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.accentGold.withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldBright),
                  ),
                ),
              )
            : base64Bytes != null
                ? Image.memory(
                    base64Bytes,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildFallback(initial),
                  )
                : (photoUrl != null && photoUrl!.isNotEmpty)
                    ? Image.network(
                        photoUrl!,
                        width: radius * 2,
                        height: radius * 2,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildFallback(initial),
                      )
                    : _buildFallback(initial),
      ),
    );

    if (!showEditButton) {
      return avatarContent;
    }

    final editButtonSize = (radius * 0.72).clamp(24.0, 34.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarContent,
        Positioned(
          bottom: -2,
          right: -2,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onEditPressed,
              borderRadius: BorderRadius.circular(editButtonSize / 2),
              child: Container(
                width: editButtonSize,
                height: editButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGold,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: editButtonSize * 0.52,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallback(String initial) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.goldBright,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.82,
        ),
      ),
    );
  }
}
