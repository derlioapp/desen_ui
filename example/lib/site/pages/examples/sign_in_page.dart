import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';
import '../../links.dart';
import 'frame.dart';

/// Examples: sign in and sign up.
class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    eyebrow: 'Examples',
    title: 'Sign in',
    lead:
        'A sign-in card with its siblings: create an account and reset a '
        'password. Any email signs in with the password `northwind`; any '
        'other password shows the server\'s error.',
    sections: [
      DocSection(
        title: 'Preview',
        children: [
          ScreenFrame(label: 'Northwind sign in', child: NorthwindSignIn()),
        ],
      ),
      DocSection(
        title: 'Built with',
        children: [
          BuiltWith([
            ('Card', '/components/card'),
            ('Form fields', '/forms'),
            ('Text field', '/components/text-field'),
            ('Checkbox', '/components/checkbox'),
            ('Button', '/components/button'),
            ('Link', '/components/link'),
            ('Alert', '/components/alert'),
            ('Progress', '/components/progress'),
            ('Toast', '/components/toast'),
          ]),
        ],
      ),
    ],
  );
}

enum _Mode { signIn, signUp, reset, signedIn, verify, resetSent }

/// The demo password the fake server accepts.
const _demoPassword = 'northwind';

/// A centered auth card that moves between signing in, signing up and
/// resetting a password.
class NorthwindSignIn extends StatefulWidget {
  const NorthwindSignIn({super.key});

  @override
  State<NorthwindSignIn> createState() => _NorthwindSignInState();
}

class _NorthwindSignInState extends State<NorthwindSignIn> {
  _Mode _mode = _Mode.signIn;

  /// The address the last step was about, for the confirmation cards.
  String _email = '';

  void _go(_Mode mode, [String? email]) => setState(() {
    _mode = mode;
    if (email != null) _email = email;
  });

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final card = switch (_mode) {
      _Mode.signIn => _SignInForm(
        email: _email,
        onSignedIn: (e) => _go(_Mode.signedIn, e),
        onSignUp: () => _go(_Mode.signUp),
        onForgot: (e) => _go(_Mode.reset, e),
      ),
      _Mode.signUp => _SignUpForm(
        onCreated: (e) => _go(_Mode.verify, e),
        onSignIn: () => _go(_Mode.signIn),
      ),
      _Mode.reset => _ResetForm(
        email: _email,
        onSent: (e) => _go(_Mode.resetSent, e),
        onBack: () => _go(_Mode.signIn),
      ),
      _Mode.signedIn => _Done(
        icon: DsIcons.circleCheck,
        status: DsStatus.success,
        title: 'You\'re signed in',
        body: 'Signed in as $_email.',
        primary: 'Open the dashboard',
        onPrimary: () => SiteLinks.of(context).go('/examples/dashboard'),
        secondary: 'Sign out',
        onSecondary: () => _go(_Mode.signIn),
      ),
      _Mode.verify => _Done(
        icon: DsIcons.mail,
        status: DsStatus.info,
        title: 'Check your inbox',
        body:
            'We sent a link to $_email. Open it to confirm your address and '
            'finish setting up Northwind.',
        primary: 'Resend the link',
        onPrimary: () => showDsToast(
          context: context,
          title: 'Link sent again',
          description: _email,
        ),
        secondary: 'Back to sign in',
        onSecondary: () => _go(_Mode.signIn),
      ),
      _Mode.resetSent => _Done(
        icon: DsIcons.mail,
        status: DsStatus.info,
        title: 'Check your inbox',
        body:
            'If $_email has an account, a reset link is on its way. It works '
            'for 30 minutes.',
        primary: 'Back to sign in',
        onPrimary: () => _go(_Mode.signIn),
      ),
    };
    return LayoutBuilder(
      builder: (context, c) {
        final phone = c.maxWidth < 480;
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: phone ? 560 : 680),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: phone ? 16 : 32,
              vertical: phone ? 32 : 56,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 24,
                  children: [
                    const _Brand(),
                    DsCard(
                      style: DsCardStyle(
                        padding: EdgeInsets.all(phone ? 20 : 28),
                      ),
                      child: KeyedSubtree(key: ValueKey(_mode), child: card),
                    ),
                    Text(
                      '© 2026 Northwind Labs · Privacy · Terms',
                      textAlign: TextAlign.center,
                      style: t.typography.caption.copyWith(color: k.textSubtle),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 10,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: k.accent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            'N',
            style: t.typography.bodyStrong.copyWith(
              color: k.onAccent,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        Text('Northwind', style: t.typography.heading.copyWith(color: k.text)),
      ],
    );
  }
}

/// The card's title and a line under it.
class _Heading extends StatelessWidget {
  const _Heading(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: t.typography.title.copyWith(color: t.colors.text),
          ),
        ),
        Text(
          subtitle,
          style: t.typography.body.copyWith(color: t.colors.textMuted),
        ),
      ],
    );
  }
}

/// "Already have an account? Sign in": a line with a link.
class _SwitchLine extends StatelessWidget {
  const _SwitchLine(this.text, this.link, this.onPressed);

  final String text;
  final String link;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final style = t.typography.small;
    return Text.rich(
      TextSpan(
        text: '$text ',
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: DsLink(
              label: link,
              onPressed: onPressed,
              style: DsLinkStyle(textStyle: style),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: style.copyWith(color: t.colors.textMuted),
    );
  }
}

/// A full-width button.
Widget _wide(Widget button) => SizedBox(width: double.infinity, child: button);

class _SignInForm extends StatefulWidget {
  const _SignInForm({
    required this.email,
    required this.onSignedIn,
    required this.onSignUp,
    required this.onForgot,
  });

  final String email;
  final ValueChanged<String> onSignedIn;
  final VoidCallback onSignUp;
  final ValueChanged<String> onForgot;

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _form = GlobalKey<FormState>();

  /// Off until the first submit, then errors follow every edit.
  AutovalidateMode _validate = AutovalidateMode.disabled;
  late final _email = TextEditingController(text: widget.email);
  bool _remember = true;
  bool _loading = false;
  bool _rejected = false;
  String _password = '';

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _rejected = false);
    setState(() => _validate = AutovalidateMode.onUserInteraction);
    if (!_form.currentState!.validateAndFocus()) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _loading = false);
    if (_password == _demoPassword) {
      widget.onSignedIn(_email.text.trim());
    } else {
      setState(() => _rejected = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return Form(
      key: _form,
      autovalidateMode: _validate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          const _Heading('Sign in', 'Welcome back. Use your work email.'),
          _wide(
            DsButton(
              variant: .secondary,
              leading: const DsIcon(DsIcons.globe),
              onPressed: () => showDsToast(
                context: context,
                title: 'Single sign-on',
                description: 'Your company has not set it up yet.',
              ),
              child: const Text('Continue with SSO'),
            ),
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(child: Container(height: 1, color: k.border)),
              Text(
                'or',
                style: t.typography.small.copyWith(color: k.textSubtle),
              ),
              Expanded(child: Container(height: 1, color: k.border)),
            ],
          ),
          if (_rejected)
            const DsAlert(
              status: DsStatus.danger,
              announce: true,
              title: Text('Email or password is incorrect'),
              description: Text(
                'Check both and try again, or reset your password.',
              ),
            ),
          DsTextFormField(
            controller: _email,
            label: const Text('Email'),
            placeholder: 'you@company.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: DsValidators.all([
              DsValidators.required(context),
              DsValidators.email(context),
            ]),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              DsTextFormField(
                label: const Text('Password'),
                obscureText: true,
                revealable: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onChanged: (v) => _password = v,
                onSubmitted: (_) => _submit(),
                validator: DsValidators.required(context),
              ),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  DsCheckbox(
                    value: _remember,
                    label: const Text('Remember me'),
                    onChanged: (v) => setState(() => _remember = v ?? false),
                  ),
                  DsLink(
                    label: 'Forgot password?',
                    onPressed: () => widget.onForgot(_email.text.trim()),
                    style: DsLinkStyle(textStyle: t.typography.small),
                  ),
                ],
              ),
            ],
          ),
          _wide(
            DsButton(
              loading: _loading,
              onPressed: _submit,
              child: const Text('Sign in'),
            ),
          ),
          _SwitchLine(
            'New to Northwind?',
            'Create an account',
            widget.onSignUp,
          ),
        ],
      ),
    );
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm({required this.onCreated, required this.onSignIn});

  final ValueChanged<String> onCreated;
  final VoidCallback onSignIn;

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _form = GlobalKey<FormState>();

  /// Off until the first submit, then errors follow every edit.
  AutovalidateMode _validate = AutovalidateMode.disabled;
  final _email = TextEditingController();
  String _password = '';
  bool _loading = false;

  static const _personal = {
    'gmail.com',
    'yahoo.com',
    'hotmail.com',
    'outlook.com',
    'icloud.com',
  };

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  /// 0 to 3: length, a digit, and a mix of cases or a symbol.
  int get _strength {
    if (_password.isEmpty) return 0;
    var s = 0;
    if (_password.length >= 10) s++;
    if (_password.contains(RegExp(r'\d'))) s++;
    if (_password.contains(RegExp(r'[A-Z]')) &&
            _password.contains(RegExp(r'[a-z]')) ||
        _password.contains(RegExp(r'[^A-Za-z0-9]'))) {
      s++;
    }
    return s;
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _validate = AutovalidateMode.onUserInteraction);
    if (!_form.currentState!.validateAndFocus()) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _loading = false);
    widget.onCreated(_email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final strength = _strength;
    final (word, status) = switch (strength) {
      0 => ('', k.neutral),
      1 => ('Weak', k.danger),
      2 => ('Fair', k.warning),
      _ => ('Strong', k.success),
    };
    return Form(
      key: _form,
      autovalidateMode: _validate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          const _Heading(
            'Create your account',
            'Free for teams of up to 10 people.',
          ),
          DsTextFormField(
            label: const Text('Full name'),
            required: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: DsValidators.required(context),
          ),
          DsTextFormField(
            controller: _email,
            label: const Text('Work email'),
            required: true,
            placeholder: 'you@company.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: DsValidators.all([
              DsValidators.required(context),
              DsValidators.email(context),
              (v) {
                final domain = v!.trim().split('@').last.toLowerCase();
                return _personal.contains(domain)
                    ? 'Use your work email, not a personal one.'
                    : null;
              },
            ]),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              DsTextFormField(
                label: const Text('Password'),
                description: const Text(
                  'At least 10 characters, with a number.',
                ),
                required: true,
                obscureText: true,
                revealable: true,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (v) => setState(() => _password = v),
                validator: DsValidators.all([
                  DsValidators.required(context),
                  DsValidators.minLength(context, 10),
                  (v) => v!.contains(RegExp(r'\d'))
                      ? null
                      : 'Add at least one number.',
                ]),
              ),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: DsProgressBar(
                      value: strength / 3,
                      style: DsProgressBarStyle(fillColor: status.fill),
                      semanticLabel: 'Password strength',
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      word,
                      textAlign: TextAlign.end,
                      style: t.typography.caption.copyWith(
                        color: status.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          DsCheckboxFormField(
            label: const Text('I agree to the Terms and the Privacy Policy'),
            required: true,
            validator: DsValidators.required(
              context,
              message: 'Accept the terms to create an account.',
            ),
          ),
          _wide(
            DsButton(
              loading: _loading,
              onPressed: _submit,
              child: const Text('Create account'),
            ),
          ),
          _SwitchLine('Already have an account?', 'Sign in', widget.onSignIn),
        ],
      ),
    );
  }
}

class _ResetForm extends StatefulWidget {
  const _ResetForm({
    required this.email,
    required this.onSent,
    required this.onBack,
  });

  final String email;
  final ValueChanged<String> onSent;
  final VoidCallback onBack;

  @override
  State<_ResetForm> createState() => _ResetFormState();
}

class _ResetFormState extends State<_ResetForm> {
  final _form = GlobalKey<FormState>();

  /// Off until the first submit, then errors follow every edit.
  AutovalidateMode _validate = AutovalidateMode.disabled;
  late final _email = TextEditingController(text: widget.email);
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _validate = AutovalidateMode.onUserInteraction);
    if (!_form.currentState!.validateAndFocus()) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _loading = false);
    widget.onSent(_email.text.trim());
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    autovalidateMode: _validate,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        const _Heading(
          'Reset your password',
          'We\'ll email you a link to choose a new one.',
        ),
        DsTextFormField(
          controller: _email,
          label: const Text('Email'),
          placeholder: 'you@company.com',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _submit(),
          validator: DsValidators.all([
            DsValidators.required(context),
            DsValidators.email(context),
          ]),
        ),
        _wide(
          DsButton(
            loading: _loading,
            onPressed: _submit,
            child: const Text('Send reset link'),
          ),
        ),
        _SwitchLine('Remembered it?', 'Back to sign in', widget.onBack),
      ],
    ),
  );
}

/// A finished step: a status icon, what happened and where to go next.
class _Done extends StatelessWidget {
  const _Done({
    required this.icon,
    required this.status,
    required this.title,
    required this.body,
    required this.primary,
    required this.onPrimary,
    this.secondary,
    this.onSecondary,
  });

  final DsIconData icon;
  final DsStatus status;
  final String title;
  final String body;
  final String primary;
  final VoidCallback onPrimary;
  final String? secondary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final tone = status == DsStatus.success ? k.success : k.info;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            width: 44,
            height: 44,
            decoration: DsBoxDecoration(
              color: tone.tint,
              borderRadius: BorderRadius.circular(t.radii.control(44)),
            ),
            child: Center(child: DsIcon(icon, size: 22, color: tone.text)),
          ),
        ),
        Semantics(liveRegion: true, child: _Heading(title, body)),
        _wide(DsButton(onPressed: onPrimary, child: Text(primary))),
        if (secondary case final label?)
          _wide(
            DsButton(
              variant: .ghost,
              onPressed: onSecondary,
              child: Text(label),
            ),
          ),
      ],
    );
  }
}
