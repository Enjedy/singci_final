import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/theme_provider.dart';
import 'pages/onboarding/onboarding_page.dart';
import 'pages/bienvenue/bienvenue.dart' show Bienvenue;
import 'translation/app_translations.dart';
//singci2026@
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hhjapqczihuobvkeyduk.supabase.co',
    publishableKey: 'sb_publishable_mWmV1B1hQc6eY6FqUvW_VQ_WFW_PA6a',
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

// --- Palette de l'application ---
class AppPalette {
  AppPalette._();

  // Degrade de fond (header)
  static const Color navyPurple = Color(0xFF26164A);
  static const Color purpleMain = Color(0xFF701460);
  static const Color electricBlue = Color(0xFF154EA6);

  // Bouton d'action principal (degrade or -> orange)
  static const Color gold = Color(0xFFFBB03B);
  static const Color vividOrange = Color(0xFFED1C24);

  // Bouton d'action secondaire (degrade turquoise -> bleu royal)
  static const Color turquoise = Color(0xFF00A896);
  static const Color royalBlue = Color(0xFF0275D8);

  static const Color creamBackground = Color(0xFFF6F3EC);
  static const Color darkBackground = Color(0xFF14101E);
  static const Color darkCard = Color(0xFF201830);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String currentLang = "fr";

  void changeLang() {
    setState(() {
      currentLang = currentLang == "fr" ? "mg" : "fr";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SignCi",
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: context.watch<ThemeProvider>().themeMode,
      home: HomePage(
        currentLang: currentLang,
        onChangeLang: changeLang,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final String currentLang;
  final VoidCallback onChangeLang;

  const HomePage({
    super.key,
    required this.currentLang,
    required this.onChangeLang,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppPalette.darkBackground : AppPalette.creamBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroHeader(
                currentLang: currentLang,
                onChangeLang: onChangeLang,
                isDark: isDark,
                onToggleTheme: () => themeProvider.toggleTheme(!isDark),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DescriptionCard(currentLang: currentLang, isDark: isDark),
                    const SizedBox(height: 16),
                    _FeatureList(currentLang: currentLang, isDark: isDark),
                    const SizedBox(height: 28),
                    _GradientButton(
                      label: AppTranslations.t('bouton', currentLang),
                      colors: const [AppPalette.gold, AppPalette.vividOrange],
                      icon: Icons.arrow_forward,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OnboardingPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _GradientButton(
                      label: AppTranslations.t('login_button', currentLang),
                      colors: const [AppPalette.turquoise, AppPalette.royalBlue],
                      icon: Icons.login,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Bienvenue()),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau superieur en degrade violet/bleu, avec logos et titre de bienvenue.
class _HeroHeader extends StatelessWidget {
  final String currentLang;
  final VoidCallback onChangeLang;
  final bool isDark;
  final VoidCallback onToggleTheme;

  const _HeroHeader({
    required this.currentLang,
    required this.onChangeLang,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppPalette.navyPurple,
              AppPalette.purpleMain,
              AppPalette.electricBlue,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleIconButton(
                  icon: Icons.translate,
                  tooltip: "Langue",
                  onPressed: onChangeLang,
                ),
                _CircleIconButton(
                  icon: isDark ? Icons.light_mode : Icons.dark_mode,
                  tooltip: "Theme",
                  onPressed: onToggleTheme,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                _LogoBadge(assetPath: "assets/image/logo.png", fallbackIcon: Icons.shield_outlined),
                SizedBox(width: 12),
                _LogoBadge(assetPath: "assets/image/logoispm.png", fallbackIcon: Icons.school_outlined),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              AppTranslations.t('welcome', currentLang),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppTranslations.t('subtitle', currentLang),
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  final String assetPath;
  final IconData fallbackIcon;

  const _LogoBadge({required this.assetPath, required this.fallbackIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(fallbackIcon, size: 26, color: AppPalette.purpleMain);
        },
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final String currentLang;
  final bool isDark;

  const _DescriptionCard({required this.currentLang, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppPalette.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppPalette.electricBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_outlined, color: AppPalette.electricBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppTranslations.t('desc_title', currentLang),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF231A33),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppTranslations.t('desc', currentLang),
            style: TextStyle(
              fontSize: 14.5,
              height: 1.6,
              color: isDark ? Colors.white70 : const Color(0xFF565266),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  final String currentLang;
  final bool isDark;

  const _FeatureList({required this.currentLang, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.bolt_outlined, AppTranslations.t('feature_report', currentLang), AppPalette.vividOrange),
      (Icons.timeline_outlined, AppTranslations.t('feature_track', currentLang), AppPalette.royalBlue),
      (Icons.auto_awesome_outlined, AppTranslations.t('feature_ai', currentLang), AppPalette.purpleMain),
    ];

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(item.$1, size: 20, color: item.$3),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : const Color(0xFF3A3548),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Bouton plein-largeur avec fond en degrade et texte blanc.
class _GradientButton extends StatelessWidget {
  final String label;
  final List<Color> colors;
  final IconData icon;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.label,
    required this.colors,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, size: 20, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}