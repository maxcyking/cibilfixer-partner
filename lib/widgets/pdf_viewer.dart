import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class PDFViewer extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PDFViewer({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PDFViewer> createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  late PdfController _pdfController;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _initializePdf();
  }

  void _initializePdf() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Download PDF from URL and load as data
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        final pdfData = response.bodyBytes;
        
        _pdfController = PdfController(
          document: PdfDocument.openData(pdfData),
        );

        // Wait for the document to load and get page count
        final document = await PdfDocument.openData(pdfData);
        _totalPages = document.pagesCount;

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
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.neutral700),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error500,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading PDF',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.error500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializePdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return PdfView(
      controller: _pdfController,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
      },
      onDocumentLoaded: (document) {
        setState(() {
          _totalPages = document.pagesCount;
        });
      },
      scrollDirection: Axis.vertical,
      backgroundDecoration: const BoxDecoration(
        color: AppColors.neutral100,
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_isLoading || _error != null || _totalPages == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.neutral200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_left),
            onPressed: _currentPage > 1
                ? () {
                    _pdfController.previousPage(
                      curve: Curves.ease,
                      duration: const Duration(milliseconds: 200),
                    );
                  }
                : null,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Page $_currentPage of $_totalPages',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral700,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 60,
                  height: 32,
                  child: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      isDense: true,
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    onSubmitted: (value) {
                      final page = int.tryParse(value);
                      if (page != null && page >= 1 && page <= _totalPages) {
                        _pdfController.animateToPage(
                          page,
                          curve: Curves.ease,
                          duration: const Duration(milliseconds: 200),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_right),
            onPressed: _currentPage < _totalPages
                ? () {
                    _pdfController.nextPage(
                      curve: Curves.ease,
                      duration: const Duration(milliseconds: 200),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
} 