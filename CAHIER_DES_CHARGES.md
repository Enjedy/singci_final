# Cahier des charges — SignCi

**Application :** SignCi (« Signalement Citoyen IA »)
**Version de l'application :** 1.0.0+1 (UI affichée : « Version 2.0 Pro »)
**Type de projet :** Application mobile Flutter + API backend PHP/MySQL + services cloud (Supabase, cartographie OpenStreetMap)
**Dernière mise à jour du document :** 15/09/2026

---

## 1. Présentation générale

SignCi est une application citoyenne développée en **Flutter (Dart)** destinée à la
**ville d'Antananarivo (Madagascar)**. Elle permet aux habitants de **signaler des
problèmes urbains** (routes, éclairage, assainissement, eau, bâtiments, écoles…),
de **suivre leur traitement**, et de **consulter une carte intelligente** des incidents.
Un « moteur d'IA » embarqué (analyse par règles/naturelle, sans appel réseau) automatise
la catégorisation, l'évaluation de la gravité, la vérification de la qualité des photos,
la détection des doublons et le calcul des zones critiques.

Le projet est composé de deux parties distinctes :

| Partie | Technologie | Rôle |
|---|---|---|
| `lib/` (cœur de l'app) | Flutter / Dart | Interface utilisateur complète |
| `api/` | PHP (PDO) + MySQL + JWT | Backend REST (inscription, connexion, gestion des signalements) |

Les signalements sont actuellement stockés dans **Supabase** (table `signalement`),
initialisée directement dans `lib/main.dart`. L'API PHP du dossier `api/` est un backend
alternatif/complémentaire (base MySQL `signci`), **non encore branché** sur l'interface Flutter.

> **Note importante :** certaines fonctionnalités sont des **maquettes fonctionnelles**
> (voir la colonne « État » du tableau des fonctionnalités) : les pages administrateur
> sont vides, la messagerie est simulée en mémoire, l'authentification des pages
> `login_page.dart` / `registration_page.dart` n'appelle pas encore l'API PHP.

---

## 2. Fonctionnalités du projet

### 2.1. Accueil, parcours de bienvenue et réglages globaux

| # | Fonctionnalité | Description | État |
|---|---|---|---|
| F1 | Page d'accueil « hero » | Bandeau dégradé violet/bleu avec logos (SignCi + ISPM), boutons **Commencer** et **J'ai déjà un compte** | Fonctionnel |
| F2 | Bascule de langue FR / MG | Traduction instantanée (français / malgache) de la page d'accueil via `AppTranslations` (fichier `lib/translation/app_translations.dart`) | Fonctionnel |
| F3 | Mode clair / sombre | Bascule du thème Material 3, mémorisé via `shared_preferences` (`ThemeProvider`) | Fonctionnel |
| F4 | Onboarding | 3 diapositives de présentation (« Passer », « Suivant », « Commencer ») avant l'entrée dans l'application | Fonctionnel |
| F5 | Choix de langue (Paramètres) | Fenêtre de sélection Français / Malagasy / English (affichage seul) | Maquette |

### 2.2. Comptes utilisateurs

| # | Fonctionnalité | Description | État |
|---|---|---|---|
| F6 | Page de connexion | Champ pseudo/email + mot de passe, lien « Créer un compte » | Maquette (navigation simulée) |
| F7 | Page d'inscription | Pseudo, email OU téléphone, mot de passe + confirmation (validation par champs) | Maquette (navigation simulée) |
| F8 | Authentification réelle (backend) | API PHP `auth/register.php` et `auth/login.php` : hachage `password_hash`, **JWT HS256** (expiration 24 h), CORS | Fonctionnel côté API, non branché sur l'UI |
| F9 | Profil utilisateur | Photo de couverture, avatar, pseudo, email, bouton « Modifier le profil » | Profil statique (« Citoyen SignCi ») |
| F10 | Déconnexion | Dialogue de confirmation puis retour à la page de connexion | Fonctionnel (simulé) |

### 2.3. Création d'un signalement (assistant en 2 étapes + aperçu)

| # | Fonctionnalité | Description | État |
|---|---|---|---|
| F11 | Étapes du formulaire | Étape 1 : type (Lieu public / Bâtiment), catégorie, problème ; Étape 2 : photos, description, GPS ; Étape 3 : aperçu + envoi | Fonctionnel |
| F12 | Localisation GPS automatique | Capture de la position via `geolocator`, **recentrage forcé sur Antananarivo** si hors zone (`minLat/maxLat/minLng/maxLng`) | Fonctionnel |
| F13 | Géocodage inverse | Conversion (lat, lng) en adresse lisible via `geocoding` ; recherche d'adresses via **Nominatim (OpenStreetMap)** | Fonctionnel |
| F14 | Carte de prévisualisation | Aperçu de la position sur tuiles **CartoDB** (`flutter_map`) avec marqueur | Fonctionnel |
| F15 | Ajout de photos | Caméra ou galerie (`image_picker`, qualité 85), aperçu, suppression, plusieurs photos | Fonctionnel |
| F16 | Validation des données | `ValidationService` : problème obligatoire, description 15–2000 caractères, adresse + GPS obligatoires (zone Antananarivo), au moins 1 photo, contrôle qualité IA (bloquant si score < 0,35) | Fonctionnel |
| F17 | Aperçu final | Récapitulatif type/catégorie/problème, description, adresse, GPS, photos, diagnostic IA | Fonctionnel |
| F18 | Envoi du signalement | Insertion dans Supabase (table `signalement`) via `SupabaseService.insertSignalement()` | Fonctionnel |
| F19 | Suppression de masse | « Supprimer tous les signalements » (Paramètres) avec confirmation | Fonctionnel |

### 2.4. Moteur d'IA embarqué (règles + traitement d'image, 100 % local)

| # | Fonctionnalité | Description | État |
|---|---|---|---|
| F20 | Analyse de la description | Tokenisation (FR + MG), extraction des 5 mots-clés, suggestion automatique du type/catégorie/problème | Fonctionnel |
| F21 | Analyse de la qualité d'image | Détection **flou**, **trop sombre**, **surexposée**, basse résolution, contraste, contenu uniforme — en isolat `Isolate.run` (hors thread UI) ; score 0→1, « hint visuel » (couleurs dominantes) | Fonctionnel |
| F22 | Vérification de cohérence | Catégorie ↔ description ↔ image (mots-clés attendus par catégorie + indice visuel) ; statuts « Cohérent », « Incohérent », « À vérifier », « Sans image » | Fonctionnel |
| F23 | Gravité / priorité | « Basse / Moyenne / Haute » selon mots-clés d'urgence (`danger`, `urgent`, `effondrement`…) | Fonctionnel |
| F24 | Score de confiance | 0,40 → 0,98 selon longueur du texte, correspondance mots-clés, qualité image, cohérence | Fonctionnel |
| F25 | Détection de doublons | Distance GPS (formule de **Haversine**, rayon 500 m), similarité texte (**Jaccard**), même catégorie → probabilité combinée ≥ 0,45 ; dialogue « Signalement similaire ! » avec bouton « Confirmer l'existant » (+1 vote) | Fonctionnel |
| F26 | Zones critiques | Clustering des signalements non résolus dans un rayon de 500 m (≥ 3) → marqueur/zone « ZONE CRITIQUE 🚨 » | Fonctionnel |
| F27 | Recalcul dynamique de la priorité | Vote citoyen : ≥ 5 « confirmations » → priorité « Haute », mise à jour automatique | Fonctionnel |
| F28 | Agent de conseil | Chat conversationnel qui génère des consignes concrètes (Jirama, eau, ordures, routes, éclairage, école, danger) avec urgence | Fonctionnel |

### 2.5. Carte intelligente

| # | Fonctionnalité | Description | État |
|---|---|---|---|
| F29 | Cartographie | `flutter_map` + tuiles CartoDB, contrainte de caméra sur Antananarivo (zoom 11–18) | Fonctionnel |
| F30 | Marqueurs d'incidents | Couleur selon priorité (rouge = Haute, orange = Moyenne, vert = Basse) ; épingles spéciales pour zones critiques | Fonctionnel |
| F31 | Position utilisateur | Marqueur bleu « ma position » | Fonctionnel |
| F32 | Filtres | « Tous », « Haute », « Zones Critiques » | Fonctionnel |
| F33 | Détails d'un incident | Bottom sheet : problème, description, adresse, confiance IA, votes, bouton « +1 Vote » | Fonctionnel |
| F34 | Cercles des zones critiques | `CircleLayer` de 500 m en rouge semi-transparent | Fonctionnel |

### 2.6. Historique et suivi

| # | Fonctionnalité | Description | État |
|---|---|---|---|
| F35 | Liste des signalements | Cartes avec type•catégorie, adresse, statut (« En attente » / « En cours » / « Résolu »), badges IA (confiance, priorité), badge zone critique | Fonctionnel |
| F36 | Galerie d'images du signalement | 1, 2 ou grille de 4 photos (+N) | Fonctionnel |
| F37 | Confirmation citoyenne | Bouton « Je confirme ce problème » → +1 vote dans Supabase | Fonctionnel |
| F38 | Actualisation | Pull-to-refresh + bouton rafraîchir | Fonctionnel |

### 2.7. Messagerie et contacts

| # | Fonctionnalité | Description | État |
|---|---|---|---|
| F39 | Liste de conversations | Recherche, non-lus, heures, aperçu du dernier message | Simulé (mémoire) |
| F40 | Nouveau message | Choix du contact : Mairie, Gendarmerie, Centre de santé, École, Jirama (Eau), CUA Propreté | Simulé |
| F41 | Chat avec réponses automatiques | Envoi de messages, pièces jointes (photo / position / alerte signalement), réponses auto du contact | Simulé |
| F42 | Persistance | Les conversations restent vivantes pendant la session (aucune persistance disque) | Simulé |

### 2.8. Backend PHP / MySQL (dossier `api/`)

| # | Fonctionnalité | Description | État |
|---|---|---|---|
| F43 | Inscription | `POST api/auth/register.php` — pseudo, email, mot de passe ≥ 4 caractères ; renvoie JWT + user ; 409 si doublon | Fonctionnel (API) |
| F44 | Connexion | `POST api/auth/login.php` — pseudo OU email + mot de passe vérifié ; renvoie JWT | Fonctionnel (API) |
| F45 | JWT | Encodage/décodage HS256 maison, expiration 24 h, middleware `require_auth()` | Fonctionnel (API) |
| F46 | Récupération des signalements | `GET api/signalements.php` (authentifié) — liste triée par id desc | Fonctionnel (API) |
| F47 | Création d'un signalement | `POST` action `create` — champ obligatoires : catégorie, problème, description ; 201 + id | Fonctionnel (API) |
| F48 | Vote | `POST` action `upvote` — +1 vote + passage auto priorité « Haute » à 5 votes | Fonctionnel (API) |
| F49 | Statut | `POST` action `status` — changement de statut | Fonctionnel (API) |
| F50 | Zone critique | `POST` action `critical` — marquage multi-ids | Fonctionnel (API) |
| F51 | Suppression totale | `POST` action `delete` — purge de la table `signalement` | Fonctionnel (API) |
| F52 | Schéma MySQL | `api/schema.sql` : base `signci`, tables `users` et `signalement` (utf8mb4) | Fonctionnel |

### 2.9. Éléments non fonctionnels / à venir

| # | Élément | Commentaire |
|---|---|---|
| F53 | Panneau administrateur | Les fichiers `lib/pages/admin/*` (login, inscription, accueil, statistiques, carte) sont **vides** |
| F54 | Notifications FCM | `firebase_core` présent mais **stub** (`FirebaseService.sendStatusNotification` vide) ; aucun fichier `google-services.json` |
| F55 | Synchronisation Firebase | Stub — `syncPendingSignalements()` renvoie toujours 0 ; `firebase_core_web/app_links` sont des dépendances transitives |
| F56 | Page « Signalement » (`nasandratra/report_page.dart`) | Esquisse simplifiée non reliée au moteur |
| F57 | Recherche d'adresse | `api.dart` / `adreesfield.dart` interrogent Nominatim OSM (nécessite internet) |

---

## 3. Outils et dépendances à installer

### 3.1. Environnement de développement (requis pour compiler l'app)

| Outil | Rôle |
|---|---|
| **Flutter SDK** (canal stable) | Framework de l'application mobile |
| **Dart SDK** | Intégré à Flutter, langage du code applicatif |
| **Android Studio** (ou outils CLI Android) | Compilation du build Android (APK) |
| **Java Development Kit (JDK) 17** | Requis par `android/app/build.gradle.kts` (`source/targetCompatibility = VERSION_17`) |
| **Un éditeur de code** | Android Studio, VS Code (+ extensions Flutter/Dart), etc. |
| **Git** (optionnel) | Contrôle de version et récupération du projet |

### 3.2. Outils du backend (dossier `api/`)

| Outil | Rôle |
|---|---|
| **PHP ≥ 8.0** (8.2+ recommandé) | Exécution de l'API REST, PDO MySQL |
| **MySQL ≥ 5.7** (8.x recommandé) | Base de données `signci` |
| **Apache** (via XAMPP / WAMP / Laragon) | Serveur web hébergeant `api/` |
| **phpMyAdmin** (optionnel) | Saisie du schéma SQL et admin de la base |
| **Composer** | Non requis (aucune dépendance PHP externe ; utilisation de PDO natif + JSON) |

### 3.3. Services cloud / externes (à configurer)

| Service | Utilisation | Action requise |
|---|---|---|
| **Supabase** (gratuit) | Stockage principal des signalements (table `signalement`) | Projet, table + clés.url et `publishableKey` dans `lib/main.dart:11-14` |
| **CartoDB (tuiles)** | Fonds de carte | Aucune clé requise (URL publique) |
| **Nominatim / OpenStreetMap** | Géocodage inverse + recherche d'adresse | Aucune clé requise, internet obligatoire |

---

## 4. Versions exactes requises

### 4.1. Langages et SDK

| Composant | Version exigée |
|---|---|
| Dart SDK (dans `<pubspec.yaml>`) | **`^3.11.1`** (minimum 3.11.1) |
| Flutter | **canal stable** — révision `ff37bef603469fb030f2b72995ab929ccfc227f0` `.metadata` |
| Version Dart résolue du projet (`.dart_tool/version`) | **3.47.2** |
| Java (JDK) | **17** |
| PHP | **≥ 8.0** (développement réalisé sous 8.x, fonctions `password_hash`, `str_contains`-compatibles, PDO) |
| MySQL | **≥ 5.7** (charset `utf8mb4`) |

### 4.2. Dépendances Flutter (directes) — `pubspec.yaml` + `pubspec.lock`

| Paquet | Contrainte `pubspec.yaml` | Version verrouillée (`pubspec.lock`) |
|---|---|---|
| `image_picker` | `^1.0.7` | **1.2.1** |
| `http` | `^1.6.0` | **1.6.0** |
| `cupertino_icons` | `^1.0.8` | **1.0.8** |
| `connectivity_plus` | `^7.3.1` | **7.3.1** |
| `flutter_map` | `^6.0.0` | **6.2.1** |
| `latlong2` | `^0.9.0` | **0.9.1** |
| `geolocator` | `^13.0.0` | **13.0.4** |
| `geocoding` | `^3.0.0` | **3.0.0** |
| `provider` | `^6.1.2` | **6.1.5+1** |
| `shared_preferences` | `^2.3.0` | **2.5.5** |
| `supabase_flutter` | `^2.0.0` | **2.17.2** |
| `firebase_core` | `^4.14.0` | **4.14.0** |
| `image` | `^4.10.1` | **4.10.1** |

### 4.3. Dépendances de développement

| Paquet | Contrainte | Version verrouillée |
|---|---|---|
| `flutter_test` | SDK Flutter | sdk |
| `flutter_launcher_icons` | `^0.13.1` | **0.13.1** |
| `flutter_lints` | `^6.0.0` | **6.0.0** |

> Les versions ci-dessus sont celles réellement résolues à la dernière génération du
> projet. Le fichier `pubspec.lock` doit être conservé pour reproduire **exactement**
> ces versions sur une autre machine.

---

## 5. Guide d'installation pas à pas

### Étape 1 — Installer les prérequis

1. **Installer Flutter (stable)** : télécharger depuis https://docs.flutter.dev/get-started/install
   puis ajouter le dossier `flutter/bin` au `PATH`.
   Vérifier : `flutter --version` (doit accepter Dart ≥ 3.11).
2. **Installer Android Studio** (avec SDK Android + outils de ligne de commande) puis
   lancer `flutter doctor` pour valider l'environnement.
3. **Installer un JDK 17** (ex. Temurin/OpenJDK 17) et le déclarer dans Android Studio.
4. **Pour le backend** : installer **XAMPP** (Apache + PHP + MySQL + phpMyAdmin) ou équivalent.

### Étape 2 — Récupérer le projet

```
git clone <URL_du_dépôt_SignCi>
cd signci
```

Ou copier le dossier du projet à l'identique (inclure impérativement `pubspec.*`, `lib/`,
`api/`, `assets/`, `android/`, `web/`, `windows/`, etc.).

### Étape 3 — Réinstaller les dépendances Flutter

```
flutter pub get
```

(Ceci régénère `pubspec.lock`, `.dart_tool/` et vérifie la cohérence des versions.)

### Étape 4 — Configurer Supabase (stockage des signalements)

1. Créer un projet sur https://supabase.com (gratuit).
2. Dans l'éditeur SQL de Supabase, créer la table (SQL Editor) :

```sql
create table if not exists signalement (
  id bigserial primary key,
  type text,
  categorie text,
  probleme text,
  description text,
  adresse text,
  image text,
  status text default 'En attente',
  latitude double precision,
  longitude double precision,
  priorite text default 'Moyenne',
  "confidenceScore" double precision default 0.80,
  keywords text,
  "upvotesCount" bigint default 1,
  "isDuplicate" smallint default 0,
  "duplicateOfId" text,
  "isCriticalZone" smallint default 0,
  "createdAt" text,
  "userId" text,
  "userPseudo" text
);
```

3. Ouvrir `lib/main.dart` et remplacer l'URL et la clé annotées par les vôtres :

```dart
await Supabase.initialize(
  url: 'https://VOTRE-PROJET.supabase.co',
  publishableKey: 'VOTRE_CLE_PUBLIQUE',
);
```

### Étape 5 — Configurer le backend PHP / MySQL (optionnel, API)

1. Lancer Apache + MySQL dans XAMPP.
2. Créer la base et les tables via `api/schema.sql` (phpMyAdmin ou CLI :
   `mysql -u root < api/schema.sql`).
3. Adapter `api/config.php` si nécessaire (hôte, base, utilisateur, mot de passe) et
   **changer `JWT_SECRET`** :

```php
const DB_HOST = 'localhost';
const DB_NAME = 'signci';
const DB_USER = 'root';
const DB_PASS = '';
const JWT_SECRET = 'ULTRA_LONGUE_CHAINE_ALEATOIRE_A_CHANGER';
```

4. Placer le dossier `api/` sous le répertoire web (`htdocs` pour XAMPP). Test :
   `http://localhost/api/auth/register.php` → réponse JSON `Méthode non autorisée` (405)
   si le serveur répond correctement.

### Étape 6 — Lancer l'application

Vérifications complémentaires :
- `flutter analyze` — analyse statique (aucune erreur bloquante attendue)
- `flutter test` — exécute la suite de tests unitaires du dossier `test/`
- `flutter doctor` — environnement sain

Lancement sur un appareil/émulateur **Android** (recommandé, car il utilise caméra, GPS
et galerie) :

```
flutter run
```

Autres cibles disponibles (scaffolding présent) :

```
flutter run -d chrome          # Web
flutter run -d windows         # Windows desktop
flutter build apk              # APK de production (Android)
flutter build web --release    # Build web
```

Génération de l'icône applicative (package `flutter_launcher_icons`) :

```
dart run flutter_launcher_icons
```

### Étape 7 — Vérifications post-installation

1. À l'écran d'accueil : basculer français/malgache et mode sombre.
2. Créer un signalement : la position GPS doit s'afficher dans **Antananarivo**,
   l'IA doit répondre « Assistante IA SignCi Prête », puis déclencher une analyse
   (catégorie, confiance, cohérence).
3. Envoyer le signalement : il doit apparaître dans l'**Historique** et sur la **Carte**.
4. Vérifier la présence de la donnée dans Supabase (table `signalement`).

---

## 6. Points d'attention pour un transfert / déploiement

- **Ne jamais publier la clé Supabase `publishableKey`** dans un dépôt public (elle est
  actuellement codée en dur dans `lib/main.dart`).
- **Le `pubspec.lock` doit voyager avec le projet** pour garantir les versions exactes.
- **Secrets backend** : changer `JWT_SECRET` et les identifiants MySQL (`api/config.php`).
- L'application est volontairement **limitée à Antananarivo** (bornes GPS + contrainte
  de caméra) ; pour changer de ville, modifier `LocationService` et la contrainte de carte.
- Android autorise déjà INTERNET via le manifest par défaut des plugins ; penser à
  déclarer les permissions caméra/bouton si besoin des plugins natifs
  (`image_picker`, `geolocator`, `geocoding`).
- Les répertoires `build/`, `.dart_tool/` et les fichiers IDE (`.idea/`) peuvent être
  exclus du transfert : ils seront régénérés par `flutter pub get`.

---

## 7. Commandes utiles (récapitulatif)

```bash
flutter --version          # vérifier la version de Flutter
flutter doctor             # vérifier le SDK Android, le JDK…
flutter pub get            # installer les dépendances
flutter analyze            # analyse statique du code
flutter test               # tests unitaires
flutter run                # lancer en mode développement (Android par défaut)
flutter build apk          # générer l'APK
dart run flutter_launcher_icons  # régénérer les icônes de l'application
```