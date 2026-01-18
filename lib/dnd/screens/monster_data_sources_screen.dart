import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_background.dart';

/// Settings screen for managing monster data sources
class MonsterDataSourcesScreen extends StatefulWidget {
  const MonsterDataSourcesScreen({super.key});

  @override
  State<MonsterDataSourcesScreen> createState() =>
      _MonsterDataSourcesScreenState();
}

class _MonsterDataSourcesScreenState extends State<MonsterDataSourcesScreen> {
  final TextEditingController _apiUrlController = TextEditingController();
  bool _showWarning = true;

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  void _showCopyrightWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('⚠️ Copyright Warning', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'IMPORTANT LEGAL NOTICE',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Monsters from paid D&D sourcebooks (Volo\'s Guide, Mordenkainen\'s Tome, Xanathar\'s Guide, etc.) are copyrighted by Wizards of the Coast.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 12),
              Text(
                'Accessing, downloading, or using copyrighted content without permission is ILLEGAL and may violate:',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 8),
              Text(
                '• Copyright law\n'
                '• Digital Millennium Copyright Act (DMCA)\n'
                '• Terms of Service agreements',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  '⚖️ By proceeding, you acknowledge that you are solely responsible for ensuring you have the legal right to access any content you add.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'LEGAL ALTERNATIVES:',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '✅ Purchase official books from D&D Beyond\n'
                '✅ Use SRD content (included in this app)\n'
                '✅ Use Open Gaming License content',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  Future<void> _openApiDocumentation(String name, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Monster Data Sources',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Warning Banner
                    if (_showWarning)
                      GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber,
                                  color: Colors.orange,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Copyright Notice',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white54,
                                  ),
                                  onPressed: () =>
                                      setState(() => _showWarning = false),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This app includes 334 SRD monsters legally. Additional content may be copyrighted.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _showCopyrightWarning,
                              icon: const Icon(Icons.info_outline),
                              label: const Text('Read Full Warning'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.withValues(
                                  alpha: 0.3,
                                ),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Current Sources
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.greenAccent,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Active Sources',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSourceTile(
                            '✅ Local SRD Database',
                            '334 monsters • Offline • Legal',
                            Icons.storage,
                            Colors.green,
                          ),
                          const Divider(color: Colors.white24),
                          _buildSourceTile(
                            '🌐 Open5e API',
                            'api.open5e.com • Online • Community Content',
                            Icons.cloud,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Available API Sources
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available API Sources',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Community-maintained APIs. User discretion advised.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildApiReference(
                            name: 'D&D 5e API',
                            description: 'Complete SRD content',
                            url: 'https://www.dnd5eapi.co',
                            endpoint: 'https://www.dnd5eapi.co/api/monsters',
                            legal: true,
                          ),
                          const Divider(color: Colors.white24),

                          _buildApiReference(
                            name: '5e-bits/5e-srd-api',
                            description: 'GitHub-based SRD API',
                            url: 'https://github.com/5e-bits/5e-srd-api',
                            endpoint: 'https://www.dnd5eapi.co/api/monsters',
                            legal: true,
                          ),
                          const Divider(color: Colors.white24),

                          _buildApiReference(
                            name: 'Open5e',
                            description: 'Open Gaming License content',
                            url: 'https://open5e.com',
                            endpoint: 'https://api.open5e.com/monsters',
                            legal: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Manual API Entry
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.settings, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Custom API Endpoint',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _apiUrlController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter API URL (at your own risk)',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.link,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showCopyrightWarning();
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Custom Source'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.withValues(
                                      alpha: 0.3,
                                    ),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '⚠️ You are responsible for legal compliance',
                            style: TextStyle(
                              color: Colors.orange.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Purchase Official Content
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.shopping_cart,
                                color: Colors.greenAccent,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Support the Creators',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Get legal access to all D&D content:',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _openApiDocumentation(
                              'D&D Beyond',
                              'https://www.dndbeyond.com',
                            ),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Visit D&D Beyond'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.withValues(
                                alpha: 0.3,
                              ),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color, size: 32),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 12,
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildApiReference({
    required String name,
    required String description,
    required String url,
    required String endpoint,
    required bool legal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              legal ? Icons.verified : Icons.warning,
              color: legal ? Colors.greenAccent : Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  endpoint,
                  style: TextStyle(
                    color: Colors.blue.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              color: Colors.white54,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: endpoint));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Endpoint copied')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              color: Colors.white54,
              onPressed: () => _openApiDocumentation(name, url),
            ),
          ],
        ),
      ],
    );
  }
}
