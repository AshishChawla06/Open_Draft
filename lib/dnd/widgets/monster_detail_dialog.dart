import 'package:flutter/material.dart';
import '../models/monster.dart';
import '../../widgets/glass_container.dart';
import 'package:flutter/foundation.dart';

class MonsterDetailDialog extends StatelessWidget {
  final Monster monster;

  const MonsterDetailDialog({super.key, required this.monster});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Title and Image
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monster.name,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${monster.size} ${monster.type} • ${monster.alignment}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (monster.imgUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        kIsWeb
                            ? 'https://corsproxy.io/?${Uri.encodeComponent(monster.imgUrl!)}'
                            : monster.imgUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(height: 32, color: Colors.white24),

              // Core Stats (AC, HP, Speed)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'AC',
                    monster.armorClass.toString(),
                    monster.armorDesc ?? 'natural armor',
                  ),
                  _buildStatItem(
                    'HP',
                    monster.hitPoints.toString(),
                    monster.hitDice,
                  ),
                  _buildStatItem(
                    'CR',
                    monster.challengeRating.toString(),
                    'XP: ${_getXpForCr(monster.challengeRating)}',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Ability Scores
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildAbilityScore('STR', monster.strength),
                    _buildAbilityScore('DEX', monster.dexterity),
                    _buildAbilityScore('CON', monster.constitution),
                    _buildAbilityScore('INT', monster.intelligence),
                    _buildAbilityScore('WIS', monster.wisdom),
                    _buildAbilityScore('CHA', monster.charisma),
                  ],
                ),
              ),
              const Divider(height: 48, color: Colors.white24),

              // Description
              if (monster.description != null &&
                  monster.description!.isNotEmpty) ...[
                const Text(
                  'Description',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  monster.description!,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
              ],

              // Actions
              const Text(
                'Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              ...monster.actions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.white),
                          children: [
                            TextSpan(
                              text: '${action.name}. ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            TextSpan(text: action.desc),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String sub) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildAbilityScore(String label, int score) {
    int mod = (score - 10) ~/ 2;
    String modStr = mod >= 0 ? '+$mod' : '$mod';

    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
          Text(
            score.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '($modStr)',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _getXpForCr(double cr) {
    final xpMap = {
      0.0: '0',
      0.125: '25',
      0.25: '50',
      0.5: '100',
      1.0: '200',
      2.0: '450',
      3.0: '700',
      4.0: '1,100',
      5.0: '1,800',
      6.0: '2,300',
      7.0: '2,900',
      8.0: '3,900',
      9.0: '5,000',
      10.0: '5,900',
      11.0: '7,200',
      12.0: '8,400',
      13.0: '10,000',
      14.0: '11,500',
      15.0: '13,000',
      16.0: '15,000',
      17.0: '18,000',
      18.0: '20,000',
      19.0: '22,000',
      20.0: '25,000',
    };
    return xpMap[cr] ?? 'Unknown';
  }
}
