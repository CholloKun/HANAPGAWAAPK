import 'package:flutter/material.dart';

class HanapGawaLogo extends StatelessWidget {
  final double size;
  final bool showSubtitle;

  const HanapGawaLogo({
    super.key,
    this.size = 80,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF800000);
    const deepMaroon = Color(0xFF5A0000);
    const accentGold = Color(0xFFFFC107);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [maroonColor, deepMaroon],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: maroonColor.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
            Positioned(
              top: size * 0.16,
              child: Icon(
                Icons.location_on,
                color: accentGold,
                size: size * 0.40,
              ),
            ),
            Positioned(
              bottom: size * 0.20,
              child: Icon(
                Icons.handyman_rounded,
                color: Colors.white,
                size: size * 0.48,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HANAP ',
              style: TextStyle(
                fontSize: size * 0.32,
                fontWeight: FontWeight.w900,
                color: maroonColor,
                letterSpacing: 1.2,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: size * 0.08,
                vertical: size * 0.02,
              ),
              decoration: BoxDecoration(
                color: maroonColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'GAWA',
                style: TextStyle(
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w900,
                  color: accentGold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            'ON-DEMAND WORKER & SERVICE BOOKING',
            style: TextStyle(
              fontSize: size * 0.13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 0.8,
            ),
          ),
        ],
      ],
    );
  }
}
