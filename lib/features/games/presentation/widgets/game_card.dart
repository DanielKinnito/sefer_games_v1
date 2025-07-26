import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:sefer_games_v1/features/games/domain/entities/game_info.dart';

class GameCard extends StatefulWidget {
  final GameInfo game;

  const GameCard({Key? key, required this.game}) : super(key: key);

  @override
  _GameCardState createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  Color? dominantColor;

  @override
  void initState() {
    super.initState();
    _extractDominantColor();
  }

  Future<void> _extractDominantColor() async {
    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      AssetImage(widget.game.iconPath),
    );
    setState(() {
      dominantColor = paletteGenerator.dominantColor?.color ?? Colors.grey;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo/Image section
          Expanded(
            child: Container(
              color: dominantColor ?? (isDarkMode ? Colors.grey[800] : Colors.grey[300]),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  widget.game.iconPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.gamepad_outlined, size: 50);
                  },
                ),
              ),
            ),
          ),
          // Name section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            color: theme.cardColor,
            child: Text(
              widget.game.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
