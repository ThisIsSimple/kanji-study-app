import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// 플래시카드 학습 개수 선택 다이얼로그
class FlashcardCountSelector extends StatefulWidget {
  final int totalCount; // 필터링된 전체 항목 개수
  final int defaultCount; // 기본값 (10개)

  const FlashcardCountSelector({
    super.key,
    required this.totalCount,
    this.defaultCount = 10,
  });

  @override
  State<FlashcardCountSelector> createState() => _FlashcardCountSelectorState();

  /// Show bottom sheet and return selected count (or null if canceled)
  static Future<int?> show(BuildContext context, int totalCount) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => FlashcardCountSelector(totalCount: totalCount),
    );
  }
}

class _FlashcardCountSelectorState extends State<FlashcardCountSelector> {
  late int _selectedCount;
  final TextEditingController _customCountController = TextEditingController();
  String? _errorMessage;

  // 미리 정의된 옵션
  final List<int> _presetOptions = [10, 20, 30, 50];

  @override
  void initState() {
    super.initState();
    _selectedCount = widget.defaultCount;
    _customCountController.text = _selectedCount.toString();
  }

  @override
  void dispose() {
    _customCountController.dispose();
    super.dispose();
  }

  void _selectPresetCount(int count) {
    setState(() {
      _selectedCount = count;
      _customCountController.text = count.toString();
      _errorMessage = null;
    });
  }

  void _selectAllCount() {
    setState(() {
      _selectedCount = widget.totalCount;
      _customCountController.text = widget.totalCount.toString();
      _errorMessage = null;
    });
  }

  void _onCustomCountChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _errorMessage = '개수를 입력해주세요';
      });
      return;
    }

    final count = int.tryParse(value);
    if (count == null) {
      setState(() {
        _errorMessage = '올바른 숫자를 입력해주세요';
      });
      return;
    }

    if (count < 1) {
      setState(() {
        _errorMessage = '최소 1개 이상 선택해주세요';
      });
      return;
    }

    if (count > widget.totalCount) {
      setState(() {
        _errorMessage = '최대 ${widget.totalCount}개까지 선택 가능합니다';
      });
      return;
    }

    setState(() {
      _selectedCount = count;
      _errorMessage = null;
    });
  }

  void _onConfirm() {
    if (_errorMessage != null) {
      return;
    }

    Navigator.of(context).pop(_selectedCount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                '학습할 카드 개수를 선택하세요',
                style: theme.typography.lg.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // 미리 정의된 버튼들 (2x2 그리드)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 3.5,
                physics: const NeverScrollableScrollPhysics(),
                children: _presetOptions.map((count) {
                  final isSelected = _selectedCount == count;
                  return GestureDetector(
                    onTap: () => _selectPresetCount(count),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colors.primary.withValues(alpha: 0.1)
                            : theme.colors.muted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? theme.colors.primary
                              : theme.colors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$count개',
                          style: theme.typography.base.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? theme.colors.primary
                                : theme.colors.foreground,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // 직접 입력 필드
              Text(
                '또는 직접 입력:',
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FTextField(
                          controller: _customCountController,
                          keyboardType: TextInputType.number,
                          maxLines: 1,
                          onChange: _onCustomCountChanged,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '개',
                        style: theme.typography.base.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _errorMessage!,
                      style: theme.typography.xs.copyWith(
                        color: theme.colors.error,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // 전체 버튼
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _selectAllCount,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedCount == widget.totalCount
                          ? theme.colors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedCount == widget.totalCount
                            ? theme.colors.primary
                            : theme.colors.border,
                        width: _selectedCount == widget.totalCount ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '전체 (${widget.totalCount}개)',
                        style: theme.typography.base.copyWith(
                          fontWeight: _selectedCount == widget.totalCount
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedCount == widget.totalCount
                              ? theme.colors.primary
                              : theme.colors.foreground,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed bottom button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FButton(
                  onPress: _errorMessage == null ? _onConfirm : null,
                  child: const Text('시작'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
