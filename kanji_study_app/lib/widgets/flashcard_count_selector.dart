import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Show dialog and return selected count (or null if canceled)
  static Future<int?> show(BuildContext context, int totalCount) {
    return showDialog<int>(
      context: context,
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

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        '학습할 카드 개수를 선택하세요',
        style: theme.typography.lg.copyWith(
          fontWeight: FontWeight.bold,
          fontFamily: 'SUITE',
        ),
      ),
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 미리 정의된 버튼들 (2x2 그리드)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
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
                            fontFamily: 'SUITE',
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
                  fontFamily: 'SUITE',
                  color: theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _customCountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  suffixText: '개',
                  errorText: _errorMessage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                style: theme.typography.base.copyWith(fontFamily: 'SUITE'),
                onChanged: _onCustomCountChanged,
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
                          fontFamily: 'SUITE',
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '취소',
            style: TextStyle(
              fontFamily: 'SUITE',
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
        TextButton(
          onPressed: _errorMessage == null ? _onConfirm : null,
          child: Text(
            '시작',
            style: TextStyle(
              fontFamily: 'SUITE',
              color: _errorMessage == null
                  ? theme.colors.primary
                  : theme.colors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
