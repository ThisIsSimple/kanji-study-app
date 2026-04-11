import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../services/handwriting_recognition_service.dart';

Future<String?> showKanjiHandwritingSheet(
  BuildContext context, {
  required Set<String> availableKanjiCharacters,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    requestFocus: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.88,
        child: KanjiHandwritingSheet(
          availableKanjiCharacters: availableKanjiCharacters,
        ),
      );
    },
  );
}

class KanjiHandwritingSheet extends StatefulWidget {
  final Set<String> availableKanjiCharacters;

  const KanjiHandwritingSheet({
    super.key,
    required this.availableKanjiCharacters,
  });

  @override
  State<KanjiHandwritingSheet> createState() => _KanjiHandwritingSheetState();
}

class _KanjiHandwritingSheetState extends State<KanjiHandwritingSheet> {
  final HandwritingRecognitionService _recognitionService =
      HandwritingRecognitionService.instance;

  List<HandwritingStrokeData> _strokes = const [];
  List<String> _candidates = const [];
  Size _canvasSize = Size.zero;
  bool _isCheckingModel = true;
  bool _isModelReady = false;
  bool _isDownloadingModel = false;
  bool _isRecognizing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadModelStatus();
  }

  Future<void> _loadModelStatus() async {
    try {
      final isDownloaded =
          await _recognitionService.isJapaneseModelDownloaded();
      if (!mounted) return;
      setState(() {
        _isModelReady = isDownloaded;
        _isCheckingModel = false;
        _statusMessage = isDownloaded
            ? null
            : '일본어 필기 인식 모델을 먼저 내려받아야 합니다.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isCheckingModel = false;
        _statusMessage = '모델 상태를 확인하지 못했습니다: $error';
      });
    }
  }

  Future<void> _downloadModel() async {
    setState(() {
      _isDownloadingModel = true;
      _statusMessage = null;
    });

    try {
      final didDownload = await _recognitionService.downloadJapaneseModel();
      if (!mounted) return;

      setState(() {
        _isModelReady = didDownload;
        _statusMessage = didDownload ? null : '모델 다운로드에 실패했습니다.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statusMessage = '모델 다운로드 중 오류가 발생했습니다: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingModel = false;
        });
      }
    }
  }

  void _clearCanvas() {
    setState(() {
      _strokes = const [];
      _candidates = const [];
      _statusMessage = null;
    });
  }

  void _addStrokePoint(Offset localPosition, {required bool startNewStroke}) {
    final boundedPoint = Offset(
      localPosition.dx.clamp(0.0, _canvasSize.width),
      localPosition.dy.clamp(0.0, _canvasSize.height),
    );

    final point = HandwritingStrokePointData(
      x: boundedPoint.dx,
      y: boundedPoint.dy,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _candidates = const [];
      _statusMessage = null;

      if (startNewStroke || _strokes.isEmpty) {
        _strokes = [
          ..._strokes,
          HandwritingStrokeData(points: [point]),
        ];
        return;
      }

      final updatedLastStroke = HandwritingStrokeData(
        points: [..._strokes.last.points, point],
      );
      _strokes = [
        ..._strokes.sublist(0, _strokes.length - 1),
        updatedLastStroke,
      ];
    });
  }

  Future<void> _recognize() async {
    if (_strokes.isEmpty) {
      setState(() {
        _statusMessage = '먼저 한 글자를 써주세요.';
      });
      return;
    }

    setState(() {
      _isRecognizing = true;
      _statusMessage = null;
    });

    try {
      final recognizedCandidates = await _recognitionService.recognizeSingleKanji(
        strokes: _strokes,
        writingArea: _canvasSize,
      );

      final matchedCandidates = recognizedCandidates
          .where(widget.availableKanjiCharacters.contains)
          .take(5)
          .toList();

      if (!mounted) return;

      setState(() {
        _candidates = matchedCandidates;
        if (matchedCandidates.isEmpty) {
          _statusMessage = recognizedCandidates.isEmpty
              ? '인식 결과가 없습니다. 조금 더 크게 또박또박 써보세요.'
              : '앱 데이터와 일치하는 한자 후보를 찾지 못했습니다.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statusMessage = '필기 인식에 실패했습니다: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRecognizing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '손글씨로 한자 찾기',
                        style: theme.typography.xl2.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    FButton.icon(
                      onPress: () => Navigator.of(context).pop(),
                      style: FButtonStyle.ghost(),
                      child: Icon(PhosphorIconsRegular.x, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              Expanded(
                child: _isCheckingModel
                    ? const Center(child: FCircularProgress())
                    : _isModelReady
                    ? _buildDrawingPanel(theme)
                    : _buildModelDownloadPanel(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelDownloadPanel(FThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colors.secondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.downloadSimple,
            size: 40,
            color: theme.colors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '필기 인식 모델 다운로드',
            style: theme.typography.lg.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage ?? '처음 한 번만 다운로드하면 이후에는 바로 사용할 수 있습니다.',
            textAlign: TextAlign.center,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          FButton(
            onPress: _isDownloadingModel ? null : _downloadModel,
            child: _isDownloadingModel
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('모델 다운로드'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingPanel(FThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _canvasSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              return Container(
                decoration: BoxDecoration(
                  color: theme.colors.secondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    _addStrokePoint(
                      details.localPosition,
                      startNewStroke: true,
                    );
                  },
                  onPanUpdate: (details) {
                    _addStrokePoint(
                      details.localPosition,
                      startNewStroke: false,
                    );
                  },
                  child: CustomPaint(
                    painter: _KanjiHandwritingPainter(
                      strokes: _strokes,
                      strokeColor: theme.colors.foreground,
                      guideColor: theme.colors.border,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FButton(
              onPress: _isRecognizing ? null : _recognize,
              child: _isRecognizing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('인식'),
            ),
            FButton(
              onPress: _strokes.isEmpty ? null : _clearCanvas,
              style: FButtonStyle.outline(),
              child: const Text('지우기'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_statusMessage != null)
          Text(
            _statusMessage!,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        if (_candidates.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '인식 후보',
            style: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _candidates.map((candidate) {
              return ActionChip(
                label: Text(
                  candidate,
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(candidate),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _KanjiHandwritingPainter extends CustomPainter {
  final List<HandwritingStrokeData> strokes;
  final Color strokeColor;
  final Color guideColor;

  const _KanjiHandwritingPainter({
    required this.strokes,
    required this.strokeColor,
    required this.guideColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = guideColor
      ..strokeWidth = 1;

    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final horizontalMid = size.height / 2;
    final verticalMid = size.width / 2;

    canvas.drawLine(
      Offset(0, horizontalMid),
      Offset(size.width, horizontalMid),
      guidePaint,
    );
    canvas.drawLine(
      Offset(verticalMid, 0),
      Offset(verticalMid, size.height),
      guidePaint,
    );
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, size.height),
      guidePaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      guidePaint,
    );

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final path = Path()
        ..moveTo(stroke.points.first.x, stroke.points.first.y);

      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.x, point.y);
      }

      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _KanjiHandwritingPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.guideColor != guideColor;
  }
}
