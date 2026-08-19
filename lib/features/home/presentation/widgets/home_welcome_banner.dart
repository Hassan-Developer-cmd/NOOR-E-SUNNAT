import 'package:flutter/material.dart';

class HomeWelcomeBanner extends StatelessWidget {
  final String userName;
  final bool isUrdu;
  final EdgeInsetsGeometry? margin;

  const HomeWelcomeBanner({
    super.key,
    required this.userName,
    this.isUrdu = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final titleText = isUrdu
        ? (userName.isNotEmpty && userName != 'مومن' && userName != 'Believer'
            ? 'خوش آمدید، $userName'
            : 'خوش آمدید')
        : (userName.isNotEmpty && userName != 'Believer'
            ? 'Welcome, $userName'
            : 'Welcome');

    final subtitleText = isUrdu
        ? 'نورِ سنت میں خوش آمدید۔ درود پاک پڑھیں اور اپنے روحانی سفر کو منور کریں۔'
        : 'Welcome to Noor-e-Sunnat. Recite Salawat, explore authentic Aqaid & Masail.';

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF064E3B), // Deep Islamic Emerald
            Color(0xFF0F766E), // Teal Green
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Islamic Mosque & Lanterns Silhouette / High-Res Image
            Positioned(
              right: isUrdu ? null : -20,
              left: isUrdu ? -20 : null,
              bottom: 0,
              top: 0,
              width: 220,
              child: Opacity(
                opacity: 0.35,
                child: Image.network(
                  'https://images.unsplash.com/photo-1564769625905-50e93615e769?q=80&w=600&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.mosque_rounded,
                      size: 110,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
            ),

            // Decorative Gradient Overlay for Text Clarity
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: isUrdu ? Alignment.centerRight : Alignment.centerLeft,
                    end: isUrdu ? Alignment.centerLeft : Alignment.centerRight,
                    colors: [
                      const Color(0xFF064E3B).withValues(alpha: 0.92),
                      const Color(0xFF064E3B).withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // Text Content & Greeting
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment:
                    isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    titleText,
                    textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      fontFamily: isUrdu ? 'UrduFont' : null,
                      shadows: const [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          offset: Offset(0, 1.5),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.58,
                    child: Text(
                      subtitleText,
                      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                      textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12.5,
                        height: isUrdu ? 1.45 : 1.35,
                        fontWeight: FontWeight.w400,
                        fontFamily: isUrdu ? 'UrduFont' : null,
                        shadows: const [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
