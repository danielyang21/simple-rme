import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';


void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const WebViewApp(),
    ),
  );
}

class WebViewApp extends StatefulWidget {
  const WebViewApp({super.key});

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
    late final WebViewController controller;
    final String internalHost = 'danielyang21-simple-rme.share.connect.posit.cloud';

    @override
    void initState() {
    super.initState();
    controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
        NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) async {
            if (!request.url.contains('danielyang21-simple-rme.share.connect.posit.cloud')) {
                final Uri uri = Uri.parse(request.url);
                debugPrint('Intercepted URL: ${uri.toString()}');

                if (uri.host != internalHost) {
                    if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                        return NavigationDecision.prevent;
                    }
                }
            }
            return NavigationDecision.navigate;
            },
        ),
        )
        ..loadRequest(Uri.parse('https://$internalHost'));
    }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(controller: controller)
    );
  }
}

