import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const Color kBlue = Color(0xFF1F4E79);
const Color kLight = Color(0xFF2E75B6);

const String kLoginUrl =
    'https://debat-z.com/wp-login.php?redirect_to=https%3A%2F%2Fdebat-z.com%2F';
const String kRegisterUrl = 'https://debat-z.com/wp-login.php?action=register';
const String kLostUrl = 'https://debat-z.com/mon-compte/lost-password/';

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
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _remember = true;
  bool _obscure = true;
  bool _busy = false;
  bool _submitted = false;
  String? _error;
  WebViewController? _web;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _login() {
    if (_user.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Renseignez votre identifiant et votre mot de passe.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _submitted = false;
    });

    final u = jsonEncode(_user.text.trim());
    final p = jsonEncode(_pass.text);
    final r = _remember ? 'true' : 'false';

    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) async {
          if (url.contains('wp-login.php')) {
            if (!_submitted) {
              _submitted = true;
              await _web!.runJavaScript(
                  "try{var u=document.getElementById('user_login');if(u)u.value=$u;"
                  "var p=document.getElementById('user_pass');if(p)p.value=$p;"
                  "var c=document.getElementById('rememberme');if(c)c.checked=$r;"
                  "var f=document.getElementById('loginform');if(f)f.submit();}catch(e){}");
            } else {
              _fail('Identifiants incorrects. Reessayez.');
            }
          } else {
            if (mounted) {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HomeShell()));
            }
          }
        },
        onWebResourceError: (_) =>
            _fail('Connexion impossible. Verifiez votre reseau.'),
      ))
      ..loadRequest(Uri.parse(kLoginUrl));
    setState(() {});
  }

  void _fail(String msg) {
    if (mounted) {
      setState(() {
        _busy = false;
        _web = null;
        _error = msg;
      });
    }
  }

  Future<void> _openRegister() async {
    final ok = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()));
    if (ok == true && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeShell()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Image.asset('assets/logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const SizedBox(height: 120)),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text('DEBAT Z',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: kBlue)),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _user,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Identifiant ou e-mail',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _pass,
                    obscureText: _obscure,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _remember,
                        onChanged: (v) =>
                            setState(() => _remember = v ?? true),
                      ),
                      const Text('Se souvenir de moi'),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _busy ? null : _login,
                      child: const Text('Se connecter',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _busy ? null : _openRegister,
                    child: const Text('Pas encore de compte ? S\'inscrire'),
                  ),
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse(kLostUrl),
                        mode: LaunchMode.externalApplication),
                    child: const Text('Mot de passe oublie ?'),
                  ),
                ],
              ),
            ),
          ),
          if (_busy)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.92),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: kBlue),
                      SizedBox(height: 14),
                      Text('Connexion...'),
                    ],
                  ),
                ),
              ),
            ),
          if (_web != null)
            SizedBox(
                width: 1, height: 1, child: WebViewWidget(controller: _web!)),
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final WebViewController _c;
  bool _loading = true;

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
          try {
            final res = await _c.runJavaScriptReturningResult(
                "(document.body && document.body.className.indexOf('logged-in')>-1)?'1':'0'");
            if (res.toString().replaceAll('"', '').trim() == '1' && mounted) {
              Navigator.pop(context, true);
            }
          } catch (_) {}
        },
      ))
      ..loadRequest(Uri.parse(kRegisterUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: kBlue,
          foregroundColor: Colors.white,
          title: const Text('Inscription')),
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
          MaterialPageRoute(builder: (_) => const LoginScreen()),
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
