import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// KakaoWebView.tsx's local ORANGE constant (distinct from AppColors.primary).
const _kWebviewOrange = Color(0xFFF57C4A);

/// Port of components/KakaoWebView.tsx: shows a Kakao place page
/// (place.map.kakao.com/{id} or place_url) inside a plain webview, used by
/// swipe/tournament/restaurant-detail. Not related to the kakao_map_plugin
/// map feature — this just renders Kakao's existing web place page.
class KakaoWebView extends StatefulWidget {
  const KakaoWebView({super.key, required this.uri});

  final String uri;

  @override
  State<KakaoWebView> createState() => _KakaoWebViewState();
}

class _KakaoWebViewState extends State<KakaoWebView> {
  late WebViewController _controller;
  bool _loading = true;

  static const _iosUserAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 '
      '(KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1';

  @override
  void initState() {
    super.initState();
    _buildController();
  }

  @override
  void didUpdateWidget(covariant KakaoWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      _buildController();
    }
  }

  void _buildController() {
    _loading = true;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_iosUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.uri));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          Container(
            color: Colors.white,
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _kWebviewOrange),
                SizedBox(height: 10),
                Text(
                  '맛집 정보를 불러오는 중...',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
