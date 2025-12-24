import 'package:shared_preferences/shared_preferences.dart';
import '../models/document_type.dart';
import '../models/template.dart';
import 'dart:convert';

class TemplateService {
  static const String _customTemplatesKey = 'custom_templates_data';

  static Future<List<Template>> getTemplates(DocumentType type) async {
    final builtIn = type == DocumentType.scp ? _scpTemplates : _novelTemplates;
    final custom = await getCustomTemplates(type);
    return [...builtIn, ...custom];
  }

  static Future<List<Template>> getCustomTemplates(DocumentType type) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_customTemplatesKey) ?? '[]';
    final List<dynamic> list = jsonDecode(data);
    return list
        .map((item) => Template.fromJson(item))
        .where((t) => t.type == type)
        .toList();
  }

  static Future<void> saveCustomTemplate(Template template) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_customTemplatesKey) ?? '[]';
    final List<dynamic> list = jsonDecode(data);

    final index = list.indexWhere((item) => item['id'] == template.id);
    if (index >= 0) {
      list[index] = template.toJson();
    } else {
      list.add(template.toJson());
    }

    await prefs.setString(_customTemplatesKey, jsonEncode(list));
  }

  static Future<void> deleteCustomTemplate(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_customTemplatesKey) ?? '[]';
    final List<dynamic> list = jsonDecode(data);
    list.removeWhere((item) => item['id'] == id);
    await prefs.setString(_customTemplatesKey, jsonEncode(list));
  }

  static final List<Template> _scpTemplates = [
    Template(
      id: 'scp_standard',
      name: 'Standard Article',
      description:
          'Default layout with Item #, Object Class, Procedures, and Description.',
      type: DocumentType.scp,
      content: jsonEncode([
        {
          "insert":
              "**Item #:** SCP-XXXX\n\n**Object Class:** Safe\n\n**Special Containment Procedures:**\n[Insert procedures here]\n\n**Description:**\n[Insert description here]\n",
        },
      ]),
    ),
    Template(
      id: 'scp_interview',
      name: 'Interview Log',
      description: 'Format for recording interviews.',
      type: DocumentType.scp,
      content: jsonEncode([
        {
          "insert":
              "**Interviewed:** [Name]\n**Interviewer:** [Name]\n**Foreword:** [Context]\n\n**<Begin Log>**\n\n**Interviewer:** [Question]\n\n**Interviewed:** [Answer]\n\n**<End Log>**\n\n**Closing Statement:** [Summary]\n",
        },
      ]),
    ),
    Template(
      id: 'scp_experiment',
      name: 'Experiment Log',
      description: 'Format for testing logs.',
      type: DocumentType.scp,
      content: jsonEncode([
        {
          "insert":
              "**Test Log SCP-XXXX - Date:** [Date]\n**Subject:** [Subject]\n**Procedure:** [Procedure]\n**Results:** [Results]\n**Analysis:** [Analysis]\n",
        },
      ]),
    ),
  ];

  static final List<Template> _novelTemplates = [
    Template(
      id: 'novel_chapter_outline',
      name: 'Chapter Outline',
      description: 'Basic structure for planning a chapter.',
      type: DocumentType.novel,
      content: jsonEncode([
        {
          "insert":
              "**Goal:** [What does the character want?]\n**Conflict:** [What stands in their way?]\n**Resolution:** [How does it end?]\n\n**Scene 1:**\n[Details]\n\n**Scene 2:**\n[Details]\n",
        },
      ]),
    ),
    Template(
      id: 'novel_character_sheet',
      name: 'Character Sheet',
      description: 'Bio and details for a character.',
      type: DocumentType.novel,
      content: jsonEncode([
        {
          "insert":
              "**Name:** [Name]\n**Age:** [Age]\n**Role:** [Role]\n\n**Physical Description:**\n[Details]\n\n**Personality:**\n[Details]\n\n**Background:**\n[History]\n",
        },
      ]),
    ),
    Template(
      id: 'novel_scene_beat',
      name: 'Scene Beat',
      description: 'Action-Reaction beat structure.',
      type: DocumentType.novel,
      content: jsonEncode([
        {
          "insert":
              "**Action:** [Character does something]\n**Reaction:** [World/Other character responds]\n**Outcome:** [New state]\n",
        },
      ]),
    ),
  ];
}
