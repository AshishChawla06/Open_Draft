import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/document_type.dart';
import '../models/scp_metadata.dart';
import '../widgets/glass_container.dart';
import '../services/image_service.dart';
import '../services/database_service.dart';
import 'book_detail_screen.dart';

class NewBookScreen extends StatefulWidget {
  final DocumentType documentType;

  const NewBookScreen({super.key, this.documentType = DocumentType.novel});

  @override
  State<NewBookScreen> createState() => _NewBookScreenState();
}

class _NewBookScreenState extends State<NewBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  XFile? _coverImage;
  bool _isCreating = false;
  late DocumentType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.documentType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    try {
      final image = await ImageService.pickImage();
      if (image != null) {
        setState(() => _coverImage = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final bookId = const Uuid().v4();

      // Save cover image if selected
      String? coverPath;
      if (_coverImage != null) {
        coverPath = await ImageService.saveImage(_coverImage!, bookId);
      }

      // Create book with initial empty chapter
      final now = DateTime.now();

      // Create SCP metadata if this is an SCP article
      SCPMetadata? scpMetadata;
      if (_selectedType == DocumentType.scp) {
        scpMetadata = SCPMetadata(
          itemNumber: 'SCP-XXXX',
          objectClass: 'Safe',
          clearanceLevel: 2,
        );
      }

      final book = Book(
        id: bookId,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        coverUrl: coverPath,
        documentType: _selectedType,
        scpMetadata: scpMetadata,
        chapters: [
          Chapter(
            id: const Uuid().v4(),
            title: _selectedType == DocumentType.scp
                ? 'Special Containment Procedures'
                : _selectedType == DocumentType.dndAdventure
                ? 'Scene 1'
                : 'Chapter 1',
            content: '',
            order: 1,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      // Save to database
      await DatabaseService.saveBook(book);

      if (mounted) {
        // Navigate to book detail screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create book: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Book',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: GlassContainer(
          borderRadius: BorderRadius.zero,
          blur: 10,
          opacity: 0.1,
          child: Container(),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Background
          Container(color: Theme.of(context).scaffoldBackgroundColor),
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),

                    // Cover Image Picker
                    Center(
                      child: SizedBox(
                        height: 200,
                        child: GestureDetector(
                          onTap: _pickCoverImage,
                          child: GlassContainer(
                            padding: const EdgeInsets.all(0),
                            color: Theme.of(context).colorScheme.surface,
                            opacity: 0.1,
                            child: AspectRatio(
                              aspectRatio: 2 / 3,
                              child: _coverImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: kIsWeb
                                          ? Image.network(
                                              _coverImage!.path,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              File(_coverImage!.path),
                                              fit: BoxFit.cover,
                                            ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 48,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Add Cover',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Document Type Selection
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      opacity: 0.1,
                      child: DropdownButtonFormField<DocumentType>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Document Type',
                          border: InputBorder.none,
                        ),
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        items: DocumentType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title Field
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.surface,
                      opacity: 0.1,
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter book title',
                          border: InputBorder.none,
                        ),
                        style: Theme.of(context).textTheme.titleLarge,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Author Field
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.surface,
                      opacity: 0.1,
                      child: TextFormField(
                        controller: _authorController,
                        decoration: const InputDecoration(
                          labelText: 'Author',
                          hintText: 'Enter author name',
                          border: InputBorder.none,
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an author';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description Field
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.surface,
                      opacity: 0.1,
                      child: TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Enter book description',
                          border: InputBorder.none,
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: 4,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Create Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isCreating ? null : _createBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isCreating
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Book',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
