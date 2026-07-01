import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const Color kBlue = Color(0xFF1F4E79);
const Color kLight = Color(0xFF2E75B6);

// Page de connexion / inscription du site (WooCommerce « Mon compte »).
const String kAccountUrl = 'https://debat-z.com/mon-compte/';

// Les 3 onglets « web » pointent vers votre site.
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
      home: const AuthGate(),
    );
  }
}

/// Petit logo reutilisable (repli sur « Z » si l'image manque).
class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 30});
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (c, e, s) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: const Text('Z',
            style: TextStyle(
                color: kBlue, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}

/// Ecran de connexion / inscription. Tant que l'utilisateur n'est pas connecte,
/// il ne peut pas acceder aux onglets.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final WebViewController _c;
  bool _loading = true;
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => _set(true),
        onPageFinished: (_) async {
          _set(false);
          await _c.runJavaScript(
              "try{var r=document.getElementById('rememberme');if(r){r.checked=true;}}catch(e){}");
          await _checkLogged();
        },
        onWebResourceError: (_) => _set(false),
      ))
      ..loadRequest(Uri.parse(kAccountUrl));
  }

  void _set(bool v) {
    if (mounted) setState(() => _loading = v);
  }

  Future<void> _checkLogged() async {
    if (_entered) return;
    try {
      final res = await _c.runJavaScriptReturningResult(
          "(document.body && document.body.className.indexOf('logged-in')>-1)?'1':'0'");
      final ok = res.toString().replaceAll('"', '').trim() == '1';
      if (ok && !_entered && mounted) {
        _entered = true;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeShell()));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 14,
        title: Row(children: const [
          Logo(size: 28),
          SizedBox(width: 8),
          Text('DEBAT Z',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1)),
        ]),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFEAF1F8),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: const Text(
              'Connectez-vous ou creez un compte pour acceder a l\'application.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kBlue),
            ),
          ),
          Expanded(
            child: Stack(children: [
              WebViewWidget(controller: _c),
              if (_loading)
                const LinearProgressIndicator(
                    color: kBlue, backgroundColor: Color(0xFFDCE6F0)),
            ]),
          ),
        ],
      ),
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
      return WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (_) => _setLoading(i, true),
          onPageFinished: (_) => _setLoading(i, false),
          onWebResourceError: (_) => _setLoading(i, false),
        ))
        ..loadRequest(Uri.parse(kWebTabs[i]['url']!));
    });
  }

  void _setLoading(int i, bool v) {
    if (mounted) setState(() => _loading[i] = v);
  }

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop) return;
    if (_index < kWebTabs.length) {
      final c = _controllers[_index];
      if (await c.canGoBack()) {
        c.goBack();
        return;
      }
    }
    if (_index != 0) setState(() => _index = 0);
  }

  Future<void> _logout() async {
    await WebViewCookieManager().clearCookies();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AuthGate()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = _index < kWebTabs.length;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 14,
          title: Row(children: const [
            Logo(size: 28),
            SizedBox(width: 8),
            Text('DEBAT Z',
                style:
                    TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1)),
          ]),
          centerTitle: false,
          actions: [
            if (isWeb)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualiser',
                onPressed: () => _controllers[_index].reload(),
              ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'logout') _logout();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'logout', child: Text('Se deconnecter')),
              ],
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
          child: Text('Retrouvez Debat-Z partout',
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
