import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/document_type.dart';
import '../services/export_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_background.dart';
import '../widgets/logo_header.dart';
import '../widgets/document_type_badge.dart';

class ExportScreen extends StatefulWidget {
  final Book book;

  const ExportScreen({super.key, required this.book});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
            color: colorScheme.onSurface,
          ),
          title: const LogoHeader(size: 40, showText: true),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {},
              color: colorScheme.onSurface,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Document',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 32),

              // Document Preview Card
              GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: BorderRadius.circular(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.book.title,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.keyboard_arrow_down, size: 24),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        DocumentTypeBadge(
                          documentType: widget.book.documentType,
                        ),
                        const SizedBox(width: 12),
                        ...widget.book.tags.map(
                          (tag) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildTag(tag),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.book.documentType == DocumentType.scp
                          ? 'Special Containment Procedures'
                          : 'Synopsis',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.book.description?.isNotEmpty == true
                          ? widget.book.description!
                          : 'No description provided.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Text(
                'Export Format',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildFormatChip('PDF', ExportFormat.pdf),
                  const SizedBox(width: 12),
                  _buildFormatChip('Docx', ExportFormat.docx),
                  const SizedBox(width: 12),
                  _buildFormatChip('HTML', ExportFormat.html),
                  const SizedBox(width: 12),
                  _buildFormatChip('Text', ExportFormat.plainText),
                ],
              ),

              const SizedBox(height: 64),

              SizedBox(
                width: double.infinity,
                height: 64,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _isExporting ? null : _handleExport,
                    child: GlassContainer(
                      color: colorScheme.primary,
                      opacity: 0.3,
                      borderRadius: BorderRadius.circular(32),
                      child: Center(
                        child: _isExporting
                            ? CircularProgressIndicator(
                                color: colorScheme.onSurface,
                              )
                            : Text(
                                'Export',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
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
    );
  }

  Widget _buildTag(String label) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      borderRadius: BorderRadius.circular(8),
      opacity: 0.1,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildFormatChip(String label, ExportFormat format) {
    final isSelected = _selectedFormat == format;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFormat = format),
        child: GlassContainer(
          height: 48,
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          opacity: isSelected ? 0.3 : 0.05,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      await ExportService.exportBook(widget.book, _selectedFormat);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}
