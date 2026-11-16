# motor-app

Casca Flutter (WebView) do [Motor](https://github.com/kyanthx-dv/motor): abre o editor e os jogos no celular.

**Como funciona:** o app empacota o motor em `assets/web`, sobe um servidor HTTP local (127.0.0.1) e mostra `editor/index.html` numa WebView. O Motor continua sendo web puro; o app so o hospeda.

**Build:** o GitHub Actions (`.github/workflows/apk.yml`) baixa o motor, gera `android/`, roda `flutter analyze` e `flutter build apk --release`. O APK sai em *Actions > ultima execucao > Artifacts > motor-app-apk*.

**Local (se tiver Flutter):** `flutter create --platforms=android .` (so uma vez), `tool/copiar_motor.sh ../motor && tool/gerar_assets.sh`, `flutter run`.

**Proximos passos:** abrir/salvar projetos no armazenamento do aparelho (downloads e seletor de arquivo da WebView), icone e nome, atualizacao do pacote do motor sem reinstalar o app.
