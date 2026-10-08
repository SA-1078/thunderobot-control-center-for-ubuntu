import 'package:flutter/material.dart';

class ColorMatrix extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const ColorMatrix({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  // Exactly matching the 4x8 Windows Reference Palette
  static const List<Color> windowsPalette = [
    // Row 1: Reds, Oranges, Yellow-Ochres
    Color(0xFFFF0000), // Pure Red
    Color(0xFFFF3B14), // Orange Red
    Color(0xFFFF6600), // Vivid Orange
    Color(0xFF8B4513), // Saddle Brown
    Color(0xFFFF8C00), // Dark Orange
    Color(0xFFFFA500), // Amber / Gold
    Color(0xFFFFC000), // Yellow Gold
    Color(0xFF808000), // Olive

    // Row 2: Yellows, Limes, Greens, Emeralds
    Color(0xFFFFFF00), // Pure Yellow
    Color(0xFFA6E22E), // Lime Green
    Color(0xFF00FF00), // Bright Green
    Color(0xFF228B22), // Forest Green
    Color(0xFF00FF66), // Neon Emerald
    Color(0xFF00FF99), // Mint Green
    Color(0xFF00FFCC), // Aqua Mint
    Color(0xFF3B6B7C), // Slate Teal

    // Row 3: Cyans, Light Blues, Blues, Indigos, Violets
    Color(0xFF00FFFF), // Electric Cyan
    Color(0xFF00BFFF), // Deep Sky Blue
    Color(0xFF1E90FF), // Dodger Blue
    Color(0xFF0033CC), // Cobalt Navy
    Color(0xFF0000FF), // Pure Blue
    Color(0xFF4B0082), // Indigo
    Color(0xFF8A2BE2), // Blue Violet
    Color(0xFF6A3B7A), // Plum Violet

    // Row 4: Magentas, Pinks, Roses, Whites
    Color(0xFFFF00FF), // Magenta / Fuchsia
    Color(0xFFFF1493), // Deep Pink
    Color(0xFFFF4081), // Accent Rose
    Color(0xFF8B0000), // Dark Crimson
    Color(0xFFFFFFFF), // Pure White
    Color(0xFFD4E6F1), // Ice Blue
    Color(0xFFE8DAEF), // Soft Lavender
    Color(0xFFFCF3CF), // Warm Cream
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PALETA DE COLORES RÁPIDOS (32 COLORES)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: windowsPalette.length,
          itemBuilder: (context, index) {
            final color = windowsPalette[index];
            final isSelected = selectedColor.value == color.value;
            return InkWell(
              onTap: () => onColorSelected(color),
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white24,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Center(
                        child: Icon(
                          Icons.check,
                          size: 16,
                          color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }
}
