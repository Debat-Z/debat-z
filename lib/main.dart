import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const Color kBlue = Color(0xFF1F4E79);
const Color kLight = Color(0xFF2E75B6);

const String kLoginUrl =
    'https://debat-z.com/wp-login.php?redirect_to=https%3A%2F%2Fdebat-z.com%2F';
const String kRegisterApi = 'https://debat-z.com/wp-json/debatz/v1/register';
const String kForgotUrl =
    'https://debat-z.com/wp-login.php?action=lostpassword';

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

InputDecoration _dec(String label, IconData icon, [Widget? suffix]) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
      suffixIcon: suffix,
    );

/// ---------------------------------------------------------------------------
/// CONNEXION (native). Peut se connecter automatiquement apres l'inscription.
/// ---------------------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  final String? initialUser;
  final String? initialPass;
  final bool autoLogin;
  const LoginScreen(
      {super.key, this.initialUser, this.initialPass, this.autoLogin = false});
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
  bool _done = false;
  String? _error;
  WebViewController? _web;

  @override
  void initState() {
    super.initState();
    if (widget.initialUser != null) _user.text = widget.initialUser!;
    if (widget.initialPass != null) _pass.text = widget.initialPass!;
    if (widget.autoLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _login());
    }
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _login() {
    if (_user.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() =>
          _error = 'Renseignez votre identifiant et votre mot de passe.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _submitted = false;
      _done = false;
    });

    final u = jsonEncode(_user.text.trim());
    final p = jsonEncode(_pass.text);
    final r = _remember ? 'true' : 'false';

    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (_submitted && !_done && !url.contains('wp-login.php')) {
            _success();
          }
        },
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
              String has = '0';
              try {
                final res = await _web!.runJavaScriptReturningResult(
                    "document.getElementById('login_error')?'1':'0'");
                has = res.toString().replaceAll('"', '').trim();
              } catch (_) {}
              if (has == '1') {
                _fail('Identifiants incorrects. Reessayez.');
              }
            }
          } else {
            _success();
          }
        },
        onWebResourceError: (_) {},
      ))
      ..loadRequest(Uri.parse(kLoginUrl));
    setState(() {});
  }

  void _success() {
    if (_done || !mounted) return;
    _done = true;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const HomeShell()));
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
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
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
                    decoration:
                        _dec('Identifiant ou e-mail', Icons.person_outline),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _pass,
                    obscureText: _obscure,
                    onSubmitted: (_) => _login(),
                    decoration: _dec(
                      'Mot de passe',
                      Icons.lock_outline,
                      IconButton(
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
                        onChanged: (v) => setState(() => _remember = v ?? true),
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
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen())),
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

/// ---------------------------------------------------------------------------
/// INSCRIPTION (native) - pseudo + e-mail + mot de passe choisi (avec criteres)
/// ---------------------------------------------------------------------------
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _user = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  bool get _cLen => _pass.text.length >= 8;
  bool get _cLetter => RegExp(r'[A-Za-z]').hasMatch(_pass.text);
  bool get _cDigit => RegExp(r'[0-9]').hasMatch(_pass.text);

  @override
  void dispose() {
    _user.dispose();
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final user = _user.text.trim();
    final email = _email.text.trim();
    final pass = _pass.text;
    if (user.length < 3) {
      setState(() => _error = 'Identifiant trop court (3 caracteres minimum).');
      return;
    }
    if (!email.contains('@') || email.length < 5) {
      setState(() => _error = 'Adresse e-mail invalide.');
      return;
    }
    if (!(_cLen && _cLetter && _cDigit)) {
      setState(() => _error =
          'Mot de passe : 8 caracteres minimum, avec au moins une lettre et un chiffre.');
      return;
    }
    if (pass != _pass2.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await http
          .post(Uri.parse(kRegisterApi),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(
                  {'user': user, 'email': email, 'password': pass}))
          .timeout(const Duration(seconds: 20));
      dynamic data;
      try {
        data = jsonDecode(r.body);
      } catch (_) {}
      if (r.statusCode == 200 && data is Map && data['success'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => LoginScreen(
                      initialUser: user,
                      initialPass: pass,
                      autoLogin: true)));
        }
      } else {
        final msg = (data is Map && data['message'] is String)
            ? data['message'] as String
            : 'Inscription impossible. Reessayez.';
        setState(() {
          _busy = false;
          _error = msg;
        });
      }
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'Connexion impossible. Verifiez votre reseau.';
      });
    }
  }

  Widget _rule(String text, bool ok) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 17, color: ok ? Colors.green : Colors.grey),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: ok ? Colors.green.shade700 : Colors.grey.shade700)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: kBlue,
          foregroundColor: Colors.white,
          title: const Text('Inscription')),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/logo.png',
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const SizedBox(height: 80)),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text('Creer un compte',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kBlue)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _user,
                    textInputAction: TextInputAction.next,
                    decoration: _dec('Identifiant', Icons.person_outline),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _dec('Adresse e-mail', Icons.mail_outline),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _pass,
                    obscureText: _obscure,
                    onChanged: (_) => setState(() {}),
                    decoration: _dec(
                      'Mot de passe',
                      Icons.lock_outline,
                      IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _rule('8 caracteres minimum', _cLen),
                  _rule('Au moins une lettre', _cLetter),
                  _rule('Au moins un chiffre', _cDigit),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _pass2,
                    obscureText: _obscure,
                    decoration:
                        _dec('Confirmer le mot de passe', Icons.lock_outline),
                  ),
                  const SizedBox(height: 16),
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
                      onPressed: _busy ? null : _register,
                      child: const Text('Creer mon compte',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
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
                      Text('Creation du compte...'),
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

/// ---------------------------------------------------------------------------
/// MOT DE PASSE OUBLIE (native) - envoie le lien de reinitialisation par e-mail
/// ---------------------------------------------------------------------------
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  bool _submitted = false;
  bool _sent = false;
  String? _error;
  WebViewController? _web;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Renseignez une adresse e-mail valide.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _submitted = false;
    });
    final e = jsonEncode(email);
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (url.contains('checkemail=confirm')) _ok();
        },
        onPageFinished: (url) async {
          if (url.contains('checkemail=confirm')) {
            _ok();
            return;
          }
          if (url.contains('action=lostpassword')) {
            if (!_submitted) {
              _submitted = true;
              await _web!.runJavaScript(
                  "try{var u=document.getElementById('user_login');if(u)u.value=$e;"
                  "var f=document.getElementById('lostpasswordform');if(f)f.submit();}catch(x){}");
            } else {
              String has = '0';
              try {
                final res = await _web!.runJavaScriptReturningResult(
                    "document.getElementById('login_error')?'1':'0'");
                has = res.toString().replaceAll('"', '').trim();
              } catch (_) {}
              if (has == '1') {
                _fail('Aucun compte trouve pour cet e-mail.');
              }
            }
          }
        },
        onWebResourceError: (_) {},
      ))
      ..loadRequest(Uri.parse(kForgotUrl));
    setState(() {});
  }

  void _ok() {
    if (_sent || !mounted) return;
    setState(() {
      _sent = true;
      _busy = false;
      _web = null;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: kBlue,
          foregroundColor: Colors.white,
          title: const Text('Mot de passe oublie')),
      body: Stack(
        children: [
          _sent ? _sentView() : _formView(),
          if (_busy)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.92),
                child: const Center(
                    child: CircularProgressIndicator(color: kBlue)),
              ),
            ),
          if (_web != null)
            SizedBox(
                width: 1, height: 1, child: WebViewWidget(controller: _web!)),
        ],
      ),
    );
  }

  Widget _formView() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 26, 26, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset('assets/logo.png',
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const SizedBox(height: 80)),
            const SizedBox(height: 16),
            const Center(
              child: Text('Mot de passe oublie',
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.bold, color: kBlue)),
            ),
            const SizedBox(height: 10),
            const Text(
              'Entrez votre e-mail. Nous vous enverrons un lien pour reinitialiser votre mot de passe.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _send(),
              decoration: _dec('Adresse e-mail', Icons.mail_outline),
            ),
            const SizedBox(height: 14),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
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
                onPressed: _busy ? null : _send,
                child: const Text('Envoyer le lien',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sentView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 72, color: kBlue),
            const SizedBox(height: 18),
            const Text('E-mail envoye !',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              'Verifiez votre boite mail : un lien pour reinitialiser votre mot de passe vous a ete envoye.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour a la connexion'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// APPLICATION (sans barre du haut, onglets charges a la demande)
/// ---------------------------------------------------------------------------
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final List<WebViewController?> _controllers = [null, null, null];
  final List<bool> _loading = [false, false, false];

  @override
  void initState() {
    super.initState();
    _ensure(0);
  }

  void _ensure(int i) {
    if (i >= kWebTabs.length || _controllers[i] != null) return;
    _loading[i] = true;
    _controllers[i] = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => _setLoading(i, true),
        onPageFinished: (_) => _setLoading(i, false),
        onWebResourceError: (_) => _setLoading(i, false),
      ))
      ..loadRequest(Uri.parse(kWebTabs[i]['url']!));
  }

  void _setLoading(int i, bool v) {
    if (mounted) setState(() => _loading[i] = v);
  }

  void _select(int i) {
    _ensure(i);
    setState(() => _index = i);
  }

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop) return;
    if (_index < kWebTabs.length) {
      final c = _controllers[_index];
      if (c != null && await c.canGoBack()) {
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
                (_controllers[i] == null)
                    ? const SizedBox.shrink()
                    : Stack(children: [
                        WebViewWidget(controller: _controllers[i]!),
                        if (_loading[i])
                          const LinearProgressIndicator(
                              color: kBlue,
                              backgroundColor: Color(0xFFDCE6F0)),
                      ]),
              LinksTab(onLogout: logout),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
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
