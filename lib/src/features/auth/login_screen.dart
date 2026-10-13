import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_client.dart';
import '../../core/session.dart';
import '../../core/theme/tokens.dart';
import '../../data/branding.dart';
import '../../data/repositories.dart';
import '../../l10n_ext.dart';
import '../../widgets/branding.dart';
import '../../widgets/language_picker.dart';

/// Two things are needed to sign in, because they are two separate parts of the
/// Komero auth contract: the credentials identify the operator, and the store
/// address picks which store to open. The backend resolves the tenant from the
/// `X-Client-Domain` header, so there is no store list to choose from — the
/// operator types their own address once and it is remembered.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _domain = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  bool _obscure = true;
  bool _remember = true;
  String? _error;

  /// The domain whose branding is currently being shown. Set on a debounce so
  /// the config is not refetched on every keystroke.
  String? _previewDomain;
  Timer? _previewDebounce;

  @override
  void initState() {
    super.initState();

    // Pre-fill from the last session so a signed-out operator only retypes the
    // password.
    final session = ref.read(sessionProvider);

    _domain.text = session.domain ?? '';
    _email.text = session.email ?? '';

    // A returning operator sees their store's logo immediately.
    if (_domain.text.isNotEmpty) {
      _previewDomain = SessionController.normalizeDomain(_domain.text);
    }

    _domain.addListener(_schedulePreview);

    _restorePassword();
  }

  /// Secure storage is async, so the saved password lands a frame or two after
  /// the form is built rather than with it.
  Future<void> _restorePassword() async {
    final saved = await ref.read(sessionProvider.notifier).rememberedPassword();

    if (!mounted || saved == null || saved.isEmpty) return;

    setState(() => _password.text = saved);
  }

  /// Look up the store's branding once typing settles. A miss is silent — the
  /// address may simply be half-typed.
  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 600), () {
      final host = SessionController.normalizeDomain(_domain.text);

      if (!mounted || host == _previewDomain) return;

      setState(() => _previewDomain = host.contains('.') ? host : null);
    });
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _domain.removeListener(_schedulePreview);
    _domain.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final l = context.l;
    final domain = SessionController.normalizeDomain(_domain.text);

    try {
      // The domain must be on the session before login: the login request
      // itself is tenant-scoped by the X-Client-Domain header.
      await ref.read(sessionProvider.notifier).setDomain(domain);

      final result = await ref.read(authRepositoryProvider).login(
            email: _email.text.trim(),
            password: _password.text,
          );

      await ref.read(sessionProvider.notifier).signIn(
            token: result.token,
            domain: domain,
            email: result.email,
          );

      await ref
          .read(sessionProvider.notifier)
          .setRememberedPassword(_remember ? _password.text : null);

      // A token that cannot read /User/me for this store is not a usable
      // session — fail here rather than on an empty dashboard.
      final me = await ref.read(authRepositoryProvider).me();

      if (me.tenant == null && !me.isPlatformAdmin) {
        await ref.read(sessionProvider.notifier).signOut();

        if (mounted) setState(() => _error = l.notAMember);

        return;
      }
    } on ApiException catch (e) {
      await ref.read(sessionProvider.notifier).signOut();

      if (!mounted) return;

      setState(() {
        _error = switch (e) {
          _ when e.status == 401 => l.invalidCredentials,
          _ when e.isTenantUnresolved || e.status == 404 => l.storeNotFound,
          _ => e.message,
        };
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    final l = context.l;

    if (email.isEmpty) {
      setState(() => _error = l.enterEmail);

      return;
    }

    setState(() => _busy = true);

    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.resetLinkSent)));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The language control belongs here, not only in
                    // settings: an operator who cannot read the form cannot
                    // reach settings to fix it.
                    Row(
                      children: [
                        // Reached by a push from the welcome screen, so it
                        // needs its own way back — there is no app bar here.
                        if (Navigator.of(context).canPop())
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back),
                          )
                        else
                          const KomeroLogo(size: 52),
                        const Spacer(),
                        const LanguageButton(),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l.loginTitle,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.loginSubtitle,
                      style: TextStyle(fontSize: 14, color: c.textMuted),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _domain,
                      autocorrect: false,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l.storeDomain,
                        hintText: l.storeDomainHint,
                        helperText: l.storeDomainHelp,
                        helperMaxLines: 2,
                        prefixIcon: const Icon(Icons.storefront_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.enterStoreDomain
                          : null,
                    ),
                    if (_previewDomain != null) ...[
                      const SizedBox(height: 12),
                      _StorePreview(domain: _previewDomain!),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      autocorrect: false,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l.email,
                        prefixIcon: const Icon(Icons.alternate_email),
                      ),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? l.enterEmail : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _busy ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: l.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? l.enterPassword : null,
                    ),
                    SwitchListTile(
                      value: _remember,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _remember = v),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l.rememberMe,
                        style: TextStyle(fontSize: 14, color: c.textSecondary),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: c.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, size: 18, color: c.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: c.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              _submit();
                            },
                      child: _busy
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: c.primaryForeground,
                              ),
                            )
                          : Text(l.signIn),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : _forgotPassword,
                      child: Text(l.forgotPassword),
                    ),
                    const SizedBox(height: 24),
                    const KomeroByline(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Confirms the operator is about to sign into the store they meant, by
/// showing that store's own logo and name as soon as the address resolves.
class _StorePreview extends ConsumerWidget {
  const _StorePreview({required this.domain});

  final String domain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final branding = ref.watch(brandingForDomainProvider(domain));

    return branding.when(
      // Nothing while it loads or fails: a half-typed address is the common
      // case, and an error box there would be noise, not information.
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (store) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            StoreLogo(branding: store, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.displayName.isEmpty ? domain : store.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                  Text(
                    domain,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.check_circle, size: 18, color: c.success),
          ],
        ),
      ),
    );
  }
}
