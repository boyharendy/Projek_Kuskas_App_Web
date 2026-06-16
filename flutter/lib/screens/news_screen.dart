import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../widgets/profile_avatar_button.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<dynamic> _newsItems = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final url = Uri.parse('https://api.rss2json.com/v1/api.json?rss_url=https%3A%2F%2Fwww.cnbcindonesia.com%2Fmarket%2Frss');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            _newsItems = data['items'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Gagal memuat berita dari server.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat berita. Periksa koneksi Anda.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan jaringan.';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan berita')),
        );
      }
    }
  }

  String _formatTime(String pubDate) {
    try {
      final date = DateTime.parse(pubDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} Menit yang lalu';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} Jam yang lalu';
      } else {
        return '${difference.inDays} Hari yang lalu';
      }
    } catch (e) {
      return 'Baru saja';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16.0,
        title: const Row(
          children: [
            ProfileAvatarButton(),
            SizedBox(width: 12),
            Text(
              'Berita Keuangan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchNews,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchNews,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_newsItems.isEmpty) {
      return const Center(
        child: Text('Tidak ada berita terbaru saat ini.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNews,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: 120, // Spacing for floating navigation bar
        ),
        itemCount: _newsItems.length, // Total items, index 0 is featured
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeaturedNews(_newsItems.first),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'Terbaru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            );
          }

          final item = _newsItems[index]; 
          return _buildNewsItem(item);
        },
      ),
    );
  }

  Widget _buildFeaturedNews(dynamic item) {
    return GestureDetector(
      onTap: () => _launchUrl(item['link'] ?? ''),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.md,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.round),
                  ),
                  child: const Text(
                    'Sorotan',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                Text(
                  _formatTime(item['pubDate'] ?? ''),
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              item['title'] ?? 'Berita Terbaru',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item['author'] != null && item['author'].toString().isNotEmpty ? 'Oleh: ${item['author']}' : 'CNBC Indonesia',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsItem(dynamic item) {
    return GestureDetector(
      onTap: () => _launchUrl(item['link'] ?? ''),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF), // Transparent glassy black/white (4% white)
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
              ),
              child: const Icon(Icons.article_rounded, color: AppColors.primaryLight, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(item['pubDate'] ?? ''),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white.withOpacity(0.5)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
