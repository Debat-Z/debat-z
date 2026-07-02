import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const Color kBlue = Color(0xFF1F4E79);
const Color kLight = Color(0xFF2E75B6);

const String kAccountUrl = 'https://debat-z.com/mon-compte/';

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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: kBlue),
      home: const AuthLanding(),
    );
  }
}

class AuthLanding extends StatelessWidget {
  const AuthLanding({super.key});

  void _openLogin(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const LoginWebView()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBlue, kLight],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Image.asset('assets/logo.png',
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const SizedBox(height: 150)),
                const SizedBox(height: 16),
                const Text('DEBAT Z',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Dragon Ball, decortique.',
                    style: TextStyle(color: Colors.white70, fontSize: 15)),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _openLogin(context),
                    child: const Text('Se connecter',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _openLogin(context),
                    child: const Text("S'inscrire",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginWebView extends StatefulWidget {
  const LoginWebView({super.key});
  @override
  State<LoginWebView> createState() => _LoginWebViewState();
}

class _LoginWebViewState extends State<LoginWebView> {
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
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (_) async {
          if (mounted) setState(() => _loading = false);
          await _c.runJavaScript(
              "try{var r=document.getElementById('rememberme');if(r){r.checked=true;}}catch(e){}");
          await _check();
        },
        onWebResourceError: (_) {
          if (mounted) setState(() => _loading = false);
        },
      ))
      ..loadRequest(Uri.parse(kAccountUrl));
  }

  Future<void> _check() async {
    if (_entered) return;
    try {
      final res = await _c.runJavaScriptReturningResult(
          "(document.body && document.body.className.indexOf('logged-in')>-1)?'1':'0'");
      if (res.toString().replaceAll('"', '').trim() == '1' &&
          !_entered &&
          mounted) {
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
          backgroundColor: kBlue,
          foregroundColor: Colors.white,
          title: const Text('Connexion / Inscription')),
      body: Stack(children: [
        WebViewWidget(controller: _c),
        if (_loading)
          const LinearProgressIndicator(
              color: kBlue, backgroundColor: Color(0xFFDCE6F0)),
      ]),
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

  Future<void> logout() async {
    await WebViewCookieManager().clearCookies();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthLanding()),
          (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _index,
            children: [
              for (int i = 0; i < kWebTabs.length; i++)
                Stack(children: [
                  WebViewWidget(controller: _controllers[i]),
                  if (_loading[i])
                    const LinearProgressIndicator(
                        color: kBlue, backgroundColor: Color(0xFFDCE6F0)),
                ]),
              LinksTab(onLogout: logout),
            ],
          ),
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
  final Future<void> Function() onLogout;
  const LinksTab({super.key, required this.onLogout});

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
          padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
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
        const Divider(height: 30),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Se deconnecter',
              style: TextStyle(
                  color: Colors.redAccent, fontWeight: FontWeight.w600)),
          onTap: onLogout,
        ),
      ],
    );
  }
}
