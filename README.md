# BairroMatch — Flutter

Versão Flutter do app original (vibe-coral-quest, feito no Lovable). Mantém paridade visual e funcional: autenticação Supabase (email/senha + Google), quiz de match, mapa com Leaflet (flutter_map + tiles CartoDB), missões gamificadas, perfil e recuperação de senha.

## Stack

- Flutter 3.19+ (Dart 3.3+)
- `supabase_flutter` — mesmo backend do app original, sem alterar schema
- `flutter_map` + `latlong2` — equivalente ao Leaflet
- `go_router` — rotas
- `flutter_riverpod` — gerenciamento de estado
- `google_fonts` — Plus Jakarta Sans
- `lucide_icons` — mesmos ícones do React original

## Pré-requisitos

Você precisa do Flutter SDK instalado. Verifique com:

```bash
flutter --version
```

Se não estiver instalado: https://docs.flutter.dev/get-started/install/macos — siga o guia, adicione o Flutter ao PATH e rode `flutter doctor` até ficar tudo verde (pelo menos Android toolchain ou Chrome).

## Rodar o projeto

### 1. Abrir no VS Code

No VS Code: **File → Open Folder → selecione a pasta `vibe_coral_quest_flutter`**. Instale a extensão **Flutter** (da Dart Code) se ainda não tem — ela adiciona o botão "Run" e auto-completion.

### 2. Gerar as pastas de plataforma

Este projeto vem com `lib/`, `assets/` e configs, mas sem as pastas nativas (android/, ios/, web/). Rode **uma vez** pra gerá-las:

```bash
flutter create . --org com.bairromatch --platforms=android,ios,web
```

Isso respeita os arquivos existentes e só adiciona o que falta.

### 3. Configurar suas chaves do Supabase

Copie o arquivo de exemplo:

```bash
cp .env.example .env
```

Abra o `.env` e preencha com as chaves do seu projeto Supabase (as mesmas que estão no `.env` do repo original):

```
SUPABASE_URL=https://SEU_PROJETO.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
```

Pega essas chaves em https://supabase.com/dashboard/project/_/settings/api

> **Atenção:** o `.env` do repo original está commitado no GitHub. Depois de migrar, rotacione a chave anon no painel do Supabase por segurança.

### 4. Instalar dependências

No terminal integrado do VS Code (`Ctrl+`` ` ou `Terminal → New Terminal`):

```bash
flutter pub get
```

### 5. Rodar o app

**No navegador (mais rápido pra testar):**

```bash
flutter run -d chrome
```

**Em emulador Android / celular conectado:**

```bash
flutter run
```
(o Flutter mostra os dispositivos disponíveis; se nenhum aparecer, abra um emulador pelo Android Studio)

**No iOS (apenas Mac):**

```bash
cd ios && pod install && cd ..
flutter run -d ios
```

## Estrutura do projeto

```
lib/
├── main.dart                      # Entry point (inicializa Supabase e dotenv)
├── app.dart                       # MaterialApp.router + tema
├── theme/
│   └── app_theme.dart             # Paleta coral + Plus Jakarta Sans
├── routing/
│   └── app_router.dart            # go_router com rotas / e /reset-password
├── services/
│   ├── supabase_service.dart      # Cliente Supabase global
│   └── nominatim_service.dart     # Geocoding OSM
├── providers/
│   ├── auth_provider.dart         # Estado de autenticação (Riverpod)
│   ├── city_provider.dart         # Cidade selecionada + aba ativa
│   └── quest_provider.dart        # Quests completadas
├── models/
│   ├── city_location.dart
│   ├── favorite_city.dart
│   └── quest.dart
├── pages/
│   ├── home_page.dart             # Container com bottom nav (ex-Index)
│   ├── auth_page.dart             # Login / cadastro / esqueci senha
│   ├── reset_password_page.dart
│   ├── match_quiz_page.dart       # Quiz com sliders + busca
│   ├── map_explorer_page.dart     # Mapa + bottom sheet com fotos
│   ├── quests_page.dart           # Missões expansíveis com XP
│   ├── profile_page.dart          # Avatar, stats, cidades, logout
│   └── not_found_page.dart
└── widgets/
    ├── bottom_nav.dart
    ├── app_text_field.dart
    └── photo_gallery.dart

assets/
└── images/                        # Fotos de bairros (copiadas do original)
```

## Paridade com o app original

| React (Lovable)                     | Flutter                                         |
| ----------------------------------- | ----------------------------------------------- |
| `@supabase/supabase-js`             | `supabase_flutter`                              |
| `react-router-dom`                  | `go_router`                                     |
| `AuthContext` + `useState`          | `Riverpod` (`authStateProvider`)                |
| `leaflet` + `react-leaflet`         | `flutter_map` + `latlong2` (mesmos tiles OSM)   |
| `@radix-ui/*` + `shadcn/ui`         | Material 3 widgets + widgets custom             |
| `lucide-react`                      | `lucide_icons` (mesmos ícones)                  |
| `sonner` (toasts)                   | `ScaffoldMessenger` / `SnackBar`                |
| `react-hook-form` + `zod`           | Validação manual no submit                      |
| Google OAuth (Lovable auth-js)      | `supabase.auth.signInWithOAuth(OAuthProvider.google)` |
| Fonte Plus Jakarta Sans             | `google_fonts`                                  |

## Próximos passos sugeridos

**Funcionalidades que o original tem em TODO e vale implementar:**

1. **Persistir quests no Supabase.** Hoje, como no original, a completude fica só na memória. A tabela `quest_progress` já existe — basta chamar `supabase.from('quest_progress').insert(...)` dentro do `complete(id)` em `lib/providers/quest_provider.dart`.

2. **Persistir cidades favoritas.** Quando a busca do quiz encontrar uma cidade, salvar em `favorite_cities` com `user_id`, `city_name`, `lat`, `lng`.

3. **Persistir preferências do quiz.** A tabela `quiz_preferences` existe — dá pra salvar os sliders a cada mudança (com debounce).

## Deploy

### Web (gratuito)

```bash
flutter build web
# upload da pasta build/web para:
# - Cloudflare Pages  (recomendado, grátis, CDN global)
# - Vercel / Netlify / Firebase Hosting / GitHub Pages
```

### Android (APK direto ou Play Store)

```bash
flutter build apk --release
# APK gerado em: build/app/outputs/flutter-apk/app-release.apk
```

Pra distribuir: Firebase App Distribution (grátis) ou Google Play (US$25 único).

### iOS

```bash
flutter build ios --release
```

Exige Mac + Xcode + Apple Developer Program (US$99/ano).

## Troubleshooting

**"Error: Could not find an option named --dart-define-from-file"**
→ Atualize o Flutter: `flutter upgrade`.

**Erro ao carregar `.env`**
→ Confirme que o arquivo `.env` existe na raiz (não `.env.example`) e está listado em `assets:` no `pubspec.yaml`.

**Mapa não aparece**
→ Verifique conexão com a internet (tiles vêm do CartoDB). Em emulador Android, confirme que a permissão de Internet está no `AndroidManifest.xml` (é adicionada automaticamente pelo `flutter_map`).

**Google OAuth não volta pro app no mobile**
→ Configure deep links: veja https://supabase.com/docs/guides/auth/native-mobile-deep-linking. Pra testar no navegador, funciona sem configuração adicional.

**Erros de `.withValues(alpha: ...)` antigos**
→ Precisa de Flutter 3.27+. Se estiver em versão mais antiga, substitua `.withValues(alpha: 0.5)` por `.withOpacity(0.5)` nos arquivos.

---

Se algo travar, me chama aqui que eu ajusto.
