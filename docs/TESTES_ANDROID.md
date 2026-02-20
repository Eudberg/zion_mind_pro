# Testes de Integracao no Android Fisico

## Checklist rapido
1. Ative `Opcoes do desenvolvedor` e `Depuracao USB` no celular.
2. Conecte por USB e aceite o prompt `Permitir depuracao USB` no Android.
3. Rode os comandos:
   - `flutter doctor`
   - `flutter devices`
   - `flutter test integration_test -d <deviceId>`
4. Opcional (legado, somente se necessario):
   - `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d <deviceId>`

## Se o device nao aparecer
- Troque o cabo USB (dados, nao apenas carga).
- No Android, use modo `Transferencia de arquivos (MTP)`.
- Reinstale/atualize drivers USB (Windows).
- Rode `adb kill-server` e depois `adb start-server`.
- Rode `flutter devices` novamente.

## VS Code
- Selecione o dispositivo fisico no seletor de device do Flutter (barra inferior).
- Execute `Flutter: Integration Test (Android device)` em Run and Debug.
- Para passar `-d` manualmente, prefira terminal com `flutter test integration_test -d <deviceId>`.
