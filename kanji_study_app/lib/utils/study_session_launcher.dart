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

  static Future<void> launchFixed<T>({
    required BuildContext context,
    required String itemType,
    required List<T> items,
    required FlashcardService flashcardService,
    required String emptyMessage,
    required List<FlashcardItem> Function(List<T> items) toFlashcardItems,
    required Future<void> Function() onComplete,
    List<T>? resumeItems,
    Future<List<T>> Function(FlashcardSession session)? loadResumeItems,
  }) async {
    if (items.isEmpty) {
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
          animation: animation,
          direction: Axis.horizontal,
          title: const Text('진행 중인 단어 학습'),
          body: const Text('진행 중인 단어 학습이 있습니다. 이어하거나 오늘 학습을 새로 시작할 수 있습니다.'),
          actions: [
            FButton(
              variant: FButtonVariant.outline,
              onPress: () async {
                final navigator = Navigator.of(dialogContext);
                await flashcardService.clearSession(itemType);
                if (!dialogContext.mounted) return;
                navigator.pop();
                _pushFlashcards(
                  context: context,
                  items: items,
                  session: null,
                  toFlashcardItems: toFlashcardItems,
                  onComplete: onComplete,
                );
              },
              child: const Text('오늘 학습 새로 시작'),
            ),
            FButton(
              onPress: () async {
                Navigator.of(dialogContext).pop();
                final itemsForResume = loadResumeItems != null
                    ? await loadResumeItems(existingSession)
                    : resumeItems ?? items;
                if (!context.mounted) return;
                _pushFlashcards(
                  context: context,
                  items: itemsForResume,
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
    _pushFlashcards(
      context: context,
      items: items,
      session: null,
      toFlashcardItems: toFlashcardItems,
      onComplete: onComplete,
    );
  }

  static Future<void> launch<T>({
    required BuildContext context,
    required String itemType,
    required List<T> filteredItems,
    required FlashcardService flashcardService,
    required String emptyMessage,
    required List<FlashcardItem> Function(List<T> items) toFlashcardItems,
    required Future<void> Function() onComplete,
    int? totalItemCount,
    Future<List<T>> Function(int count)? loadSelectedItems,
    Future<List<T>> Function(FlashcardSession session)? loadResumeItems,
  }) async {
    final availableCount = totalItemCount ?? filteredItems.length;
    if (availableCount == 0) {
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
          animation: animation,
          direction: Axis.horizontal,
          title: const Text('진행 중인 학습'),
          body: const Text('이전에 진행 중이던 플래시카드 학습이 있습니다.\n계속하시겠습니까?'),
          actions: [
            FButton(
              variant: FButtonVariant.outline,
              onPress: () async {
                final navigator = Navigator.of(dialogContext);
                await flashcardService.clearSession(itemType);
                if (!dialogContext.mounted) return;
                navigator.pop();
                await _startNewSession(
                  context: context,
                  filteredItems: filteredItems,
                  totalItemCount: availableCount,
                  loadSelectedItems: loadSelectedItems,
                  toFlashcardItems: toFlashcardItems,
                  onComplete: onComplete,
                );
              },
              child: const Text('새로 시작'),
            ),
            FButton(
              onPress: () async {
                Navigator.of(dialogContext).pop();
                final resumeItems = loadResumeItems != null
                    ? await loadResumeItems(existingSession)
                    : filteredItems;
                if (!context.mounted) return;
                _pushFlashcards(
                  context: context,
                  items: resumeItems,
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
      totalItemCount: availableCount,
      loadSelectedItems: loadSelectedItems,
      toFlashcardItems: toFlashcardItems,
      onComplete: onComplete,
    );
  }

  static Future<void> _startNewSession<T>({
    required BuildContext context,
    required List<T> filteredItems,
    required int totalItemCount,
    required Future<List<T>> Function(int count)? loadSelectedItems,
    required List<FlashcardItem> Function(List<T>) toFlashcardItems,
    required Future<void> Function() onComplete,
  }) async {
    final selectedCount = await FlashcardCountSelector.show(
      context,
      totalItemCount,
    );

    if (selectedCount == null || !context.mounted) return;
    final selectedItems = loadSelectedItems != null
        ? await loadSelectedItems(selectedCount)
        : _selectRandomItems(filteredItems, selectedCount);
    if (!context.mounted) return;
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
    if (items.isEmpty) return;

    final flashcardItems = toFlashcardItems(items);
    if (flashcardItems.isEmpty) return;

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
