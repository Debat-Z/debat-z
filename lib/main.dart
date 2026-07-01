import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const Color kBlue = Color(0xFF1F4E79);
const Color kLight = Color(0xFF2E75B6);

/// Les 3 onglets « web » pointent directement vers votre site.
const List<Map<String, String>> kWebTabs = [
  {'title': 'Site', 'url': 'https://debat-z.com/'},
  {'title': 'Forum', 'url': 'https://debat-z.com/forums/'},
  {'title': 'Messages', 'url': 'https://debat-z.com/messages/'},
];

void main() => runApp(const DebatZApp());

class DebatZApp extends StatelessWidget {
  const DebatZApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DEBAT Z',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: kBlue,
        appBarTheme: const AppBarTheme(
            backgroundColor: kBlue, foregroundColor: Colors.white),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final List<WebViewController> _controllers;
  final List<bool> _loading = [true, true, true];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(kWebTabs.length, (i) {
      final c = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (_) => _setLoading(i, true),
          onPageFinished: (_) => _setLoading(i, false),
          onWebResourceError: (_) => _setLoading(i, false),
        ))
        ..loadRequest(Uri.parse(kWebTabs[i]['url']!));
      return c;
    });
  }

  void _setLoading(int i, bool v) {
    if (mounted) setState(() => _loading[i] = v);
  }

  /// Bouton retour Android : recule dans la page web si possible.
  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop) return;
    if (_index < kWebTabs.length) {
      final c = _controllers[_index];
      if (await c.canGoBack()) {
        c.goBack();
        return;
      }
    }
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = _index < kWebTabs.length;
    final title = isWeb ? kWebTabs[_index]['title']! : 'Liens';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            if (isWeb)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualiser',
                onPressed: () => _controllers[_index].reload(),
              ),
          ],
        ),
        body: IndexedStack(
          index: _index,
          children: [
            for (int i = 0; i < kWebTabs.length; i++)
              Stack(children: [
                WebViewWidget(controller: _controllers[i]),
                if (_loading[i])
                  const LinearProgressIndicator(
                      color: kBlue, backgroundColor: Color(0xFFDCE6F0)),
              ]),
            const LinksTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.public_outlined),
                selectedIcon: Icon(Icons.public),
                label: 'Site'),
            NavigationDestination(
                icon: Icon(Icons.forum_outlined),
                selectedIcon: Icon(Icons.forum),
                label: 'Forum'),
            NavigationDestination(
                icon: Icon(Icons.mail_outline),
                selectedIcon: Icon(Icons.mail),
                label: 'Messages'),
            NavigationDestination(
                icon: Icon(Icons.link_outlined),
                selectedIcon: Icon(Icons.link),
                label: 'Liens'),
          ],
        ),
      ),
    );
  }
}

/// Onglet natif : liens vers les réseaux officiels.
class LinksTab extends StatelessWidget {
  const LinksTab({super.key});

  static const List<Map<String, dynamic>> links = [
    {'label': 'Site officiel', 'url': 'https://debat-z.com', 'icon': Icons.public, 'color': kBlue},
    {'label': 'YouTube', 'url': 'https://youtube.com/c/DebatZ', 'icon': Icons.smart_display, 'color': Color(0xFFFF0000)},
    {'label': 'TikTok', 'url': 'https://www.tiktok.com/@debat_z', 'icon': Icons.music_note, 'color': Colors.black},
    {'label': 'Instagram', 'url': 'https://www.instagram.com/debat_z/', 'icon': Icons.camera_alt, 'color': Color(0xFFC13584)},
    {'label': 'Facebook', 'url': 'https://www.facebook.com/DebatZetto/', 'icon': Icons.facebook, 'color': Color(0xFF1877F2)},
    {'label': 'X (Twitter)', 'url': 'https://x.com/Debat_Z', 'icon': Icons.alternate_email, 'color': Colors.black},
  ];

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('Retrouvez Débat-Z partout',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ...links.map((l) => ListTile(
              leading: CircleAvatar(
                backgroundColor: (l['color'] as Color).withValues(alpha: 0.12),
                child: Icon(l['icon'] as IconData, color: l['color'] as Color),
              ),
              title: Text(l['label'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _open(l['url'] as String),
            )),
      ],
    );
  }
}
