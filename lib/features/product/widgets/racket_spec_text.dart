import 'package:flutter/material.dart';

import '../../../data/models/racket_spec.dart';

class SpecText {
  const SpecText({
    required this.label,
    required this.short,
    required this.meaning,
    this.icon,
  });

  final String label;
  final String short;
  final String meaning;
  final IconData? icon;
}

abstract final class RacketSpecText {
  static const weightOrder = ['2U', '3U', '4U', '5U'];
  static const balanceOrder = ['HEAD_LIGHT', 'EVEN', 'HEAD_HEAVY'];
  static const shaftOrder = ['FLEXIBLE', 'MEDIUM', 'STIFF', 'EXTRA_STIFF'];

  static const _weights = {
    '2U': SpecText(
      label: '2U · 90–94 g',
      short: 'nặng',
      meaning: 'Nặng tay, đánh cầu đầm và uy lực',
    ),
    '3U': SpecText(
      label: '3U · 85–89 g',
      short: 'đầm tay',
      meaning: 'Đầm tay, đập cầu chắc và ổn định',
    ),
    '4U': SpecText(
      label: '4U · 80–84 g',
      short: 'nhẹ',
      meaning: 'Nhẹ, xoay vợt nhanh, dễ phòng thủ',
    ),
    '5U': SpecText(
      label: '5U · 75–79 g',
      short: 'rất nhẹ',
      meaning: 'Rất nhẹ, phản xạ nhanh, ít mỏi tay',
    ),
  };

  static const _balances = {
    'HEAD_LIGHT': SpecText(
      label: 'Head Light',
      short: 'nhẹ đầu',
      meaning: 'Nhẹ đầu: vung vợt nhanh, chặn cầu tốt',
    ),
    'EVEN': SpecText(
      label: 'Even',
      short: 'cân bằng',
      meaning: 'Cân bằng: công thủ toàn diện',
    ),
    'HEAD_HEAVY': SpecText(
      label: 'Head Heavy',
      short: 'nặng đầu',
      meaning: 'Nặng đầu: đập cầu uy lực hơn',
    ),
  };

  static const _shafts = {
    'FLEXIBLE': SpecText(
      label: 'Flexible',
      short: 'dẻo',
      meaning: 'Dẻo: dễ trợ lực, hợp người mới',
    ),
    'MEDIUM': SpecText(
      label: 'Medium',
      short: 'trung bình',
      meaning: 'Trung bình: dễ đánh mà vẫn đủ lực',
    ),
    'STIFF': SpecText(
      label: 'Stiff',
      short: 'cứng',
      meaning: 'Cứng: kiểm soát chính xác, cần lực cổ tay tốt',
    ),
    'EXTRA_STIFF': SpecText(
      label: 'Extra Stiff',
      short: 'rất cứng',
      meaning: 'Rất cứng: phản hồi tức thì, dành cho tay vợt mạnh',
    ),
  };

  static const _levels = {
    'BEGINNER': SpecText(
      label: 'Beginner',
      short: 'người mới chơi',
      meaning: 'Phù hợp người mới chơi',
      icon: Icons.emoji_people_rounded,
    ),
    'INTERMEDIATE': SpecText(
      label: 'Intermediate',
      short: 'người chơi trình độ khá',
      meaning: 'Phù hợp người chơi 1–2 năm',
      icon: Icons.trending_up_rounded,
    ),
    'ADVANCED': SpecText(
      label: 'Advanced',
      short: 'người chơi trình độ cao',
      meaning: 'Phù hợp người chơi trên 2 năm',
      icon: Icons.military_tech_rounded,
    ),
  };

  static const _styles = {
    'ATTACK': SpecText(
      label: 'Attack',
      short: 'tấn công',
      meaning: 'Dành cho lối chơi tấn công',
      icon: Icons.bolt_rounded,
    ),
    'CONTROL': SpecText(
      label: 'Control',
      short: 'kiểm soát',
      meaning: 'Dành cho lối chơi kiểm soát, điều cầu',
      icon: Icons.gps_fixed_rounded,
    ),
    'ALL_ROUND': SpecText(
      label: 'All-round',
      short: 'toàn diện',
      meaning: 'Cân bằng giữa tấn công và phòng thủ',
      icon: Icons.sync_rounded,
    ),
    'DEFENSE': SpecText(
      label: 'Defense',
      short: 'phòng thủ',
      meaning: 'Dành cho lối chơi phòng thủ, phản tạt',
      icon: Icons.shield_outlined,
    ),
  };

  static const _styleHabits = {
    'ATTACK': 'thích đập cầu',
    'CONTROL': 'thích điều cầu',
    'ALL_ROUND': 'thích lối chơi linh hoạt',
    'DEFENSE': 'thích phòng thủ phản công',
  };

  static SpecText weight(String value) => _weights[value] ?? _fallback(value);
  static SpecText balance(String value) => _balances[value] ?? _fallback(value);
  static SpecText shaft(String value) => _shafts[value] ?? _fallback(value);
  static SpecText level(String value) => _levels[value] ?? _fallback(value);
  static SpecText style(String value) => _styles[value] ?? _fallback(value);

  static String fitSummary(RacketSpec spec) {
    final habit = _styleHabits[spec.playStyle] ?? '';
    return 'Vợt ${style(spec.playStyle).short}, ${balance(spec.balance).short}, '
        'đũa ${shaft(spec.shaft).short} — hợp ${level(spec.playerLevel).short}'
        '${habit.isEmpty ? '' : ' $habit'}.';
  }

  static SpecText _fallback(String value) =>
      SpecText(label: value, short: value.toLowerCase(), meaning: '');
}
