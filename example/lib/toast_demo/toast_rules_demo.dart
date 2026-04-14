import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import '../widgets/cards/feature_card.dart';
import '../widgets/buttons/demo_button.dart';

/// Demonstrates the ToastKit rule engine: deduplication, max-trigger limits,
/// cooldown windows, and fully custom rules with stat-driven conditions.
class ToastRulesDemo extends StatefulWidget {
  const ToastRulesDemo({super.key});

  @override
  State<ToastRulesDemo> createState() => _ToastRulesDemoState();
}

class _ToastRulesDemoState extends State<ToastRulesDemo> {
  static const _dedupChannel = 'rules-dedup';
  static const _maxTriggersChannel = 'rules-max-triggers';
  static const _cooldownChannel = 'rules-cooldown';
  static const _customChannel = 'rules-custom';
  static const _maxTriggersRuleId = 'max-triggers-rule';
  static const _customRuleId = 'custom-threshold-rule';
  static const _cooldownDuration = Duration(seconds: 5);
  static const _customErrorThreshold = 5;

  int _maxTriggersSent = 0;
  int _cooldownSent = 0;
  int _customErrorsSent = 0;
  Timer? _cooldownTimer;
  int _cooldownRemaining = 0;
  bool _rulesRegistered = false;

  @override
  void initState() {
    super.initState();
    _registerChannelsAndRules();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _registerChannelsAndRules() {
    ToastKit.registerChannel(
      const ToastChannel(id: _dedupChannel, label: 'Dedup Demo'),
    );
    ToastKit.registerChannel(
      const ToastChannel(id: _maxTriggersChannel, label: 'Max Triggers Demo'),
    );
    ToastKit.registerChannel(
      const ToastChannel(id: _cooldownChannel, label: 'Cooldown Demo'),
    );
    ToastKit.registerChannel(
      const ToastChannel(id: _customChannel, label: 'Custom Rule Demo'),
    );

    ToastKit.configureRule(
      _maxTriggersChannel,
      const RuleConfig(
        errorThreshold: 1,
        maxTriggers: 3,
        deduplicateWindow: Duration(seconds: 30),
      ),
    );

    ToastKit.configureRule(
      _cooldownChannel,
      const RuleConfig(
        errorThreshold: 1,
        deduplicateWindow: _cooldownDuration,
        maxTriggers: 0,
      ),
    );

    ToastKit.addRule(
      ToastRule(
        id: _customRuleId,
        channel: _customChannel,
        condition: (stats, event) => stats.errorCount >= _customErrorThreshold,
        action: (context) {
          ToastKit.warning(
            'Error threshold of $_customErrorThreshold exceeded on '
            '"${context.channel}". Consider investigating.',
            title: '⚡ Custom Rule Fired',
          );
        },
      ),
    );

    _rulesRegistered = true;
  }

  // ---- Deduplication ----

  void _sendDuplicateMessages() {
    for (var i = 0; i < 5; i++) {
      ToastKit.info(
        'This is a duplicate message',
        title: 'Duplicate',
        channel: _dedupChannel,
      );
    }
  }

  void _sendUniqueMessages() {
    for (var i = 1; i <= 5; i++) {
      ToastKit.info(
        'Unique message #$i with distinct content',
        title: 'Message $i',
        channel: _dedupChannel,
      );
    }
  }

  // ---- Max Triggers ----

  void _triggerMaxTriggersError() {
    setState(() => _maxTriggersSent++);
    ToastKit.error(
      'Error #$_maxTriggersSent on max-triggers channel',
      title: 'Trigger Test',
      channel: _maxTriggersChannel,
    );
  }

  // ---- Cooldown ----

  void _sendCooldownError() {
    setState(() => _cooldownSent++);
    ToastKit.error(
      'Cooldown error #$_cooldownSent',
      title: 'Cooldown Test',
      channel: _cooldownChannel,
    );
    _startCooldownTimer();
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownRemaining = _cooldownDuration.inSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownRemaining--;
        if (_cooldownRemaining <= 0) {
          timer.cancel();
        }
      });
    });
  }

  // ---- Custom Rule ----

  void _triggerCustomError() {
    setState(() => _customErrorsSent++);
    ToastKit.error(
      'Custom rule error #$_customErrorsSent',
      title: 'Custom Rule Test',
      channel: _customChannel,
    );
  }

  // ---- Reset ----

  void _resetAll() {
    _cooldownTimer?.cancel();
    ToastKit.ruleEngine.clear();

    setState(() {
      _maxTriggersSent = 0;
      _cooldownSent = 0;
      _customErrorsSent = 0;
      _cooldownRemaining = 0;
      _rulesRegistered = false;
    });

    // Re-register so demo remains functional after reset
    _registerChannelsAndRules();

    ToastKit.success('All rules and stats have been reset.', title: 'Reset');
  }

  // ---- Section Builders ----

  Widget _buildDeduplicationSection() {
    return FeatureCard(
      title: 'Deduplication Rules',
      subtitle: 'Identical messages are collapsed into a single toast '
          'while unique messages are each displayed.',
      icon: Icons.filter_list_outlined,
      iconColor: Colors.indigo,
      children: [
        DemoButton(
          label: 'Send 5 Duplicate Messages',
          icon: Icons.content_copy_outlined,
          color: Colors.indigo,
          onPressed: _sendDuplicateMessages,
        ),
        DemoButton(
          label: 'Send 5 Unique Messages',
          icon: Icons.format_list_numbered,
          color: Colors.teal,
          onPressed: _sendUniqueMessages,
        ),
        const SizedBox(height: 4),
        Text(
          'Duplicate messages with identical content are collapsed by the '
          'rule engine so only one toast appears. Unique messages each '
          'produce their own toast.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMaxTriggersSection() {
    final triggerCount =
        ToastKit.ruleEngine.triggerCount(_maxTriggersRuleId);

    return FeatureCard(
      title: 'Max Triggers Rule',
      subtitle: 'A config rule with maxTriggers: 3 limits how many times '
          'the rule can fire.',
      icon: Icons.trending_up_outlined,
      iconColor: Colors.deepOrange,
      trailing: _buildCounterChip(
        '$_maxTriggersSent sent',
        Colors.deepOrange,
      ),
      children: [
        DemoButton(
          label: 'Trigger Error',
          icon: Icons.error_outline,
          color: Colors.deepOrange,
          onPressed: _triggerMaxTriggersError,
        ),
        const SizedBox(height: 8),
        _buildStatsRow(
          icon: Icons.bolt_outlined,
          label: 'Rule triggers',
          value: '$triggerCount / 3',
          color: triggerCount >= 3 ? Colors.red : Colors.deepOrange,
        ),
        if (triggerCount >= 3)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Max triggers reached — the rule will no longer fire.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCooldownSection() {
    final isInCooldown = _cooldownRemaining > 0;

    return FeatureCard(
      title: 'Cooldown Windows',
      subtitle: 'A ${_cooldownDuration.inSeconds}-second deduplication '
          'window suppresses duplicate rule triggers.',
      icon: Icons.timer_outlined,
      iconColor: Colors.blue,
      trailing: isInCooldown
          ? _buildCounterChip(
              '${_cooldownRemaining}s',
              Colors.orange,
            )
          : null,
      children: [
        DemoButton(
          label: 'Send Error Toast',
          icon: Icons.report_outlined,
          color: Colors.blue,
          onPressed: _sendCooldownError,
        ),
        const SizedBox(height: 8),
        _buildCooldownIndicator(),
        const SizedBox(height: 6),
        Text(
          isInCooldown
              ? 'Cooldown active — duplicate rule triggers are suppressed '
                  'for $_cooldownRemaining more second${_cooldownRemaining == 1 ? '' : 's'}.'
              : 'No active cooldown. Send an error to start the window.',
          style: TextStyle(
            fontSize: 12,
            color: isInCooldown ? Colors.orange.shade800 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        _buildStatsRow(
          icon: Icons.outgoing_mail,
          label: 'Errors sent',
          value: '$_cooldownSent',
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildCustomRuleSection() {
    final stats = ToastKit.ruleEngine.statsFor(_customChannel);
    final progress = (_customErrorsSent / _customErrorThreshold).clamp(0.0, 1.0);

    return FeatureCard(
      title: 'Custom Rules',
      subtitle: 'A custom ToastRule fires when errorCount ≥ '
          '$_customErrorThreshold on the channel.',
      icon: Icons.science_outlined,
      iconColor: Colors.purple,
      trailing: _buildCounterChip(
        '${stats.errorCount} / $_customErrorThreshold',
        stats.errorCount >= _customErrorThreshold
            ? Colors.red
            : Colors.purple,
      ),
      children: [
        DemoButton(
          label: 'Trigger Error',
          icon: Icons.bug_report_outlined,
          color: Colors.purple,
          onPressed: _triggerCustomError,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.purple.shade50,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.red : Colors.purple,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildStatsRow(
          icon: Icons.error_outline,
          label: 'Errors recorded',
          value: '${stats.errorCount}',
          color: Colors.red,
        ),
        _buildStatsRow(
          icon: Icons.bar_chart_outlined,
          label: 'Total events',
          value: '${stats.totalCount}',
          color: Colors.blueGrey,
        ),
        if (stats.errorCount >= _customErrorThreshold)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Threshold reached — the custom rule has fired!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
          ),
      ],
    );
  }

  // ---- Shared Helpers ----

  Widget _buildCounterChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatsRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCooldownIndicator() {
    final progress =
        (_cooldownRemaining / _cooldownDuration.inSeconds).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 8,
        backgroundColor: Colors.blue.shade50,
        valueColor: AlwaysStoppedAnimation<Color>(
          _cooldownRemaining > 0 ? Colors.orange : Colors.blue.shade200,
        ),
      ),
    );
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Rules Demo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_rulesRegistered)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Registering channels and rules…',
                textAlign: TextAlign.center,
              ),
            ),
          _buildDeduplicationSection(),
          const SizedBox(height: 12),
          _buildMaxTriggersSection(),
          const SizedBox(height: 12),
          _buildCooldownSection(),
          const SizedBox(height: 12),
          _buildCustomRuleSection(),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _resetAll,
            icon: const Icon(Icons.restart_alt_outlined),
            label: const Text('Reset All Rules'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
