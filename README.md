# motor-app (Blocky)

App Flutter do **Blocky**: rede social + editor de jogos 2D, em cima da engine [Motor](https://github.com/kyanthx-dv/motor).

## Estrutura
- `lib/main.dart`: inicia o servidor local (serve o Motor em `assets/web`) e abre o app.
- `lib/blocky/`: telas e widgets (dados de exemplo em `dados.dart`; sistemas reais entram depois, com segurança).
  - `entrada.dart` login e boas-vindas · `casca.dart` abas · `abas.dart` Início/Loja/Comunidade/Perfil
  - `busca.dart` · `jogo.dart` página e player · `detalhes.dart` post e asset · `extras.dart` carteira/notificações/chat · `criar.dart`
  - `editor_web.dart`: editor do PC em WebView (**provisório**; o editor de celular será nativo em Flutter).
- `tool/`: scripts para copiar o Motor e gerar assets.

## Build
GitHub Actions (`.github/workflows/apk.yml`): analisa e gera o APK, publicado na release **`ultimo`** (único APK, sempre o mais recente). Pode rodar manualmente em *Actions > APK > Run workflow*.

## Fluxo
Uma branch por tarefa, PR para `main`, merge só com o CI verde (a branch é apagada depois).
