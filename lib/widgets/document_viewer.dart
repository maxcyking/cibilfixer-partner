import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class DocumentViewer extends StatelessWidget {
  final String documentUrl;
  final String documentName;
  final String documentType;

  const DocumentViewer({
    super.key,
    required this.documentUrl,
    required this.documentName,
    required this.documentType,
  });

  static Future<void> show(
    BuildContext context, {
    required String documentUrl,
    required String documentName,
    required String documentType,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DocumentViewerBottomSheet(
          documentUrl: documentUrl,
          documentName: documentName,
          documentType: documentType,
        ),
      );
    } else {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => DocumentViewerDialog(
          documentUrl: documentUrl,
          documentName: documentName,
          documentType: documentType,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class DocumentViewerBottomSheet extends StatelessWidget {
  final String documentUrl;
  final String documentName;
  final String documentType;

  const DocumentViewerBottomSheet({
    super.key,
    required this.documentUrl,
    required this.documentName,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.neutral200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDocumentIcon(),
                    size: 20,
                    color: AppColors.primary600,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        documentName,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        documentType.toUpperCase(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: DocumentContent(
              documentUrl: documentUrl,
              documentName: documentName,
              documentType: documentType,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon() {
    if (_isImage(documentUrl)) {
      return Icons.image_outlined;
    } else if (_isPdf(documentUrl)) {
      return Icons.picture_as_pdf_outlined;
    } else {
      return Icons.description_outlined;
    }
  }

  bool _isImage(String url) {
    final extension = url.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  bool _isPdf(String url) {
    final extension = url.split('.').last.toLowerCase();
    return extension == 'pdf';
  }
}

class DocumentViewerDialog extends StatelessWidget {
  final String documentUrl;
  final String documentName;
  final String documentType;

  const DocumentViewerDialog({
    super.key,
    required this.documentUrl,
    required this.documentName,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: _isPdf(documentUrl) ? 1000 : 800,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.neutral200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getDocumentIcon(),
                      size: 24,
                      color: AppColors.primary600,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          documentName,
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          documentType.toUpperCase(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: DocumentContent(
                documentUrl: documentUrl,
                documentName: documentName,
                documentType: documentType,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon() {
    if (_isImage(documentUrl)) {
      return Icons.image_outlined;
    } else if (_isPdf(documentUrl)) {
      return Icons.picture_as_pdf_outlined;
    } else {
      return Icons.description_outlined;
    }
  }

  bool _isImage(String url) {
    final extension = url.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  bool _isPdf(String url) {
    final extension = url.split('.').last.toLowerCase();
    return extension == 'pdf';
  }
}

class DocumentContent extends StatelessWidget {
  final String documentUrl;
  final String documentName;
  final String documentType;

  const DocumentContent({
    super.key,
    required this.documentUrl,
    required this.documentName,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context) {
    if (_isImage(documentUrl)) {
      return _buildImageViewer();
    } else if (_isPdf(documentUrl)) {
      return _buildPdfViewer();
    } else {
      return _buildUnsupportedFileViewer();
    }
  }

  Widget _buildImageViewer() {
    return Container(
      color: Colors.black,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: documentUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary600),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading image...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            errorWidget: (context, url, error) => Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error500,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return PdfViewer(documentUrl: documentUrl);
  }

  Widget _buildUnsupportedFileViewer() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Unsupported file type',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  bool _isImage(String url) {
    final extension = url.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  bool _isPdf(String url) {
    final extension = url.split('.').last.toLowerCase();
    return extension == 'pdf';
  }
}

class PdfViewer extends StatefulWidget {
  final String documentUrl;

  const PdfViewer({
    super.key,
    required this.documentUrl,
  });

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  late PdfController _pdfController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePdfController();
  }

  void _initializePdfController() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Download PDF data from URL
      final response = await http.get(Uri.parse(widget.documentUrl));
      if (response.statusCode == 200) {
        _pdfController = PdfController(
          document: PdfDocument.openData(response.bodyBytes),
        );
        
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load PDF: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary600),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error500,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load PDF',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.error500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _initializePdfController();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            border: Border(
              bottom: BorderSide(
                color: AppColors.neutral200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  _pdfController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous Page',
              ),
              
              Expanded(
                child: Center(
                  child: PdfPageNumber(
                    controller: _pdfController,
                    builder: (_, loadingState, page, pagesCount) {
                      return Text(
                        'Page ${page ?? 0} of ${pagesCount ?? 0}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              IconButton(
                onPressed: () {
                  _pdfController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next Page',
              ),
            ],
          ),
        ),
        
        Expanded(
          child: PdfView(
            controller: _pdfController,
            scrollDirection: Axis.vertical,
            onDocumentError: (error) {
              setState(() {
                _error = error.toString();
                _isLoading = false;
              });
            },
          ),
        ),
      ],
    );
  }
} 