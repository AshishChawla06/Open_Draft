import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS-style A-Z alphabetical index for quick list navigation
class AlphabeticalIndex extends StatefulWidget {
  final List<String> availableLetters;
  final Function(String) onLetterSelected;
  final String? activeLetter;

  const AlphabeticalIndex({
    super.key,
    required this.availableLetters,
    required this.onLetterSelected,
    this.activeLetter,
  });

  @override
  State<AlphabeticalIndex> createState() => _AlphabeticalIndexState();
}

class _AlphabeticalIndexState extends State<AlphabeticalIndex> {
  String? _draggedLetter;
  bool _isDragging = false;

  static const _alphabet = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  void _handleLetterTap(String letter) {
    if (widget.availableLetters.contains(letter)) {
      HapticFeedback.selectionClick();
      widget.onLetterSelected(letter);
    }
  }

  void _handleDragUpdate(Offset localPosition, BoxConstraints constraints) {
    final double itemHeight = constraints.maxHeight / _alphabet.length;
    final int index = (localPosition.dy / itemHeight).floor().clamp(
      0,
      _alphabet.length - 1,
    );
    final String letter = _alphabet[index];

    if (_draggedLetter != letter && widget.availableLetters.contains(letter)) {
      setState(() => _draggedLetter = letter);
      HapticFeedback.selectionClick();
      widget.onLetterSelected(letter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onVerticalDragStart: (_) {
                setState(() {
                  _isDragging = true;
                  _draggedLetter = null;
                });
              },
              onVerticalDragUpdate: (details) {
                _handleDragUpdate(details.localPosition, constraints);
              },
              onVerticalDragEnd: (_) {
                setState(() {
                  _isDragging = false;
                  _draggedLetter = null;
                });
              },
              child: Container(
                width: 24,
                decoration: _isDragging
                    ? BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _alphabet.map((letter) {
                    final isAvailable = widget.availableLetters.contains(
                      letter,
                    );
                    final isActive =
                        letter == widget.activeLetter ||
                        letter == _draggedLetter;

                    return GestureDetector(
                      onTap: () => _handleLetterTap(letter),
                      child: Container(
                        height: constraints.maxHeight / _alphabet.length,
                        alignment: Alignment.center,
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: isActive ? 12 : 10,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isAvailable
                                ? (isActive
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.7))
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Letter popup overlay that appears during drag
class LetterPopup extends StatelessWidget {
  final String letter;

  const LetterPopup({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
