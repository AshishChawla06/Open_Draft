import 'package:flutter/material.dart';
import '../services/grammar_service.dart';
import '../widgets/glass_container.dart';

/// A panel that displays grammar issues for the editor
class GrammarPanel extends StatefulWidget {
  final String text;
  final Function(int offset, int length)? onIssueSelected;

  const GrammarPanel({super.key, required this.text, this.onIssueSelected});

  @override
  State<GrammarPanel> createState() => _GrammarPanelState();
}

class _GrammarPanelState extends State<GrammarPanel> {
  List<GrammarIssue> _issues = [];
  bool _isChecking = false;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load grammar check enabled from settings
    // For now, default to false
    setState(() => _enabled = false);
  }

  Future<void> _checkGrammar() async {
    if (!_enabled || widget.text.trim().isEmpty) {
      setState(() => _issues = []);
      return;
    }

    setState(() => _isChecking = true);

    try {
      final issues = await GrammarService.checkGrammar(widget.text);
      if (mounted) {
        setState(() {
          _issues = issues;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.spellcheck,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Grammar Check',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Switch(
                value: _enabled,
                onChanged: (value) {
                  setState(() => _enabled = value);
                  if (value) {
                    _checkGrammar();
                  } else {
                    setState(() => _issues = []);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_enabled) ...[
            TextButton.icon(
              onPressed: _isChecking ? null : _checkGrammar,
              icon: _isChecking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: Text(_isChecking ? 'Checking...' : 'Check Now'),
            ),
            const Divider(),
          ],
          if (_enabled && !_isChecking) ...[
            Expanded(
              child: _issues.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: Colors.green.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No issues found',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _issues.length,
                      itemBuilder: (context, index) {
                        final issue = _issues[index];
                        return _buildIssueCard(issue);
                      },
                    ),
            ),
          ] else if (!_enabled) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.spellcheck,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enable grammar check to\nfind spelling and grammar errors',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIssueCard(GrammarIssue issue) {
    Color getColorForType(String type) {
      switch (type.toLowerCase()) {
        case 'misspelling':
          return Colors.red;
        case 'grammar':
          return Colors.blue;
        case 'style':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    final color = getColorForType(issue.issueType);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          widget.onIssueSelected?.call(issue.offset, issue.length);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issue.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (issue.shortMessage.isNotEmpty &&
                  issue.shortMessage != issue.message) ...[
                const SizedBox(height: 4),
                Text(
                  issue.shortMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
              if (issue.replacements.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: issue.replacements.take(3).map((replacement) {
                    return ActionChip(
                      label: Text(
                        replacement,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        // In a real implementation, this would replace the text
                        // For now, just select the issue
                        widget.onIssueSelected?.call(
                          issue.offset,
                          issue.length,
                        );
                      },
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
