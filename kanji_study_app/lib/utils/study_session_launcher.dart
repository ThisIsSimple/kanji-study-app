import 'dart:math';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../models/flashcard_item.dart';
import '../models/flashcard_session_model.dart';
import '../screens/flashcard_screen.dart';
import '../services/flashcard_service.dart';
import '../widgets/flashcard_count_selector.dart';

class StudySessionLauncher {
  const StudySessionLauncher._();

  static Future<void> launch<T>({
    required BuildContext context,
    required String itemType,
    required List<T> filteredItems,
    required FlashcardService flashcardService,
    required String emptyMessage,
    required List<FlashcardItem> Function(List<T> items) toFlashcardItems,
    required Future<void> Function() onComplete,
  }) async {
    if (filteredItems.isEmpty) {
      final theme = FTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emptyMessage),
          backgroundColor: theme.colors.destructive,
        ),
      );
      return;
    }

    final existingSession = await flashcardService.loadSessionByType(itemType);
    if (existingSession != null &&
        !existingSession.isCompleted &&
        context.mounted) {
      showFDialog(
        context: context,
        builder: (dialogContext, style, animation) => FDialog(
          style: style.call,
          animation: animation,
          direction: Axis.horizontal,
          title: const Text('진행 중인 학습'),
          body: const Text('이전에 진행 중이던 플래시카드 학습이 있습니다.\n계속하시겠습니까?'),
          actions: [
            FButton(
              style: FButtonStyle.outline(),
              onPress: () async {
                final navigator = Navigator.of(dialogContext);
                await flashcardService.clearSession(itemType);
                if (!dialogContext.mounted) return;
                navigator.pop();
                await _startNewSession(
                  context: context,
                  filteredItems: filteredItems,
                  toFlashcardItems: toFlashcardItems,
                  onComplete: onComplete,
                );
              },
              child: const Text('새로 시작'),
            ),
            FButton(
              onPress: () {
                Navigator.of(dialogContext).pop();
                _pushFlashcards(
                  context: context,
                  items: filteredItems,
                  session: existingSession,
                  toFlashcardItems: toFlashcardItems,
                  onComplete: onComplete,
                );
              },
              child: const Text('이어하기'),
            ),
          ],
        ),
      );
      return;
    }

    if (!context.mounted) return;
    await _startNewSession(
      context: context,
      filteredItems: filteredItems,
      toFlashcardItems: toFlashcardItems,
      onComplete: onComplete,
    );
  }

  static Future<void> _startNewSession<T>({
    required BuildContext context,
    required List<T> filteredItems,
    required List<FlashcardItem> Function(List<T>) toFlashcardItems,
    required Future<void> Function() onComplete,
  }) async {
    final selectedCount = await FlashcardCountSelector.show(
      context,
      filteredItems.length,
    );

    if (selectedCount == null || !context.mounted) return;
    final selectedItems = _selectRandomItems(filteredItems, selectedCount);
    _pushFlashcards(
      context: context,
      items: selectedItems,
      session: null,
      toFlashcardItems: toFlashcardItems,
      onComplete: onComplete,
    );
  }

  static void _pushFlashcards<T>({
    required BuildContext context,
    required List<T> items,
    required FlashcardSession? session,
    required List<FlashcardItem> Function(List<T>) toFlashcardItems,
    required Future<void> Function() onComplete,
  }) {
    final flashcardItems = toFlashcardItems(items);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FlashcardScreen(items: flashcardItems, initialSession: session),
      ),
    ).then((_) => onComplete());
  }

  static List<T> _selectRandomItems<T>(List<T> items, int count) {
    if (count >= items.length) return items;

    final random = Random();
    final selectedIndices = <int>{};
    while (selectedIndices.length < count) {
      selectedIndices.add(random.nextInt(items.length));
    }
    return selectedIndices.map((index) => items[index]).toList();
  }
}
