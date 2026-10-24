# Frontend Flutter de Rastro Rural

Flutter 3.47.5, Dart y Material 3. Mantiene el diseño y los flujos comunitarios. Los tokens visuales están en `lib/theme.dart`; las fuentes y logos se empaquetan en assets.

```sh
flutter pub get
flutter analyze
flutter test
flutter build web --release --base-href /rastro-rural/ --no-web-resources-cdn
```

Java/Tomcat sirve el resultado `build/web` junto con la API. Desde la raíz: `scripts/build.ps1` y `scripts/run-local.ps1`. Para la identidad local ver `../docs/IDENTIDAD.md`. No hay persistencia offline ni almacenamiento de token en el navegador.
