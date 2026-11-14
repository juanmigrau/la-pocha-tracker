# Mobile Implementation Plan: LPT-30 Compartir resultado de la partida como imagen

## Overview

Permitir compartir el resultado final de una partida `finished` como imagen PNG
vertical 4:5 (1080×1350) más un texto breve, desde la pantalla de resultado
final y el detalle del historial. Flujo 100 % local (sin Firestore, sin Auth,
sin gating premium). Tema de marca fijo (`#2E5040`), independiente del
`ThemeMode` de la app.

- Clean Architecture: feature `share_result` con domain + presentation + data
  ligera (solo plugin de share sheet; sin Firebase).
- Estado UI: `ShareResultCubit` (`flutter_bloc` + `equatable`), mismo patrón
  que `RepeatGameCubit`.
- Ranking: reutilizar `RankingService` / `RankingEntry` / `GameDetail.finalRanking`
  para empates (1º, 1º, 3º). `RankingEntry` ya expone `rank` (int).

Referencia producto: PRD §9.1 y descripción Jira LPT-30 (`[original]` + `[enhanced]`).

## Architecture Context

```text
lib/features/share_result/
├── domain/
│   ├── entities/share_result_payload.dart
│   ├── entities/share_origin.dart              # x,y,width,height (sin Flutter)
│   ├── repositories/share_sheet_gateway.dart   # puerto abstracto
│   ├── repositories/share_result_image_renderer.dart  # puerto (inyección al cubit)
│   └── usecases/
│       ├── build_share_result_caption_usecase.dart
│       └── share_game_result_usecase.dart
├── data/
│   └── share_plus_sheet_gateway.dart          # share_plus (+ XFile / temp fijo)
└── presentation/
    ├── bloc/share_result_cubit.dart
    ├── bloc/share_result_state.dart
    ├── widgets/share_result_card.dart          # layout lógico 360×450
    ├── widgets/share_result_button.dart        # CTA + RenderBox → ShareOrigin
    └── services/share_result_image_renderer_impl.dart  # árbol de render aislado → PNG
```

**Integraciones (sin nueva ruta):**

| Pantalla | Archivo | Datos |
|----------|---------|--------|
| Resultado final | `round/presentation/pages/game_final_result_page.dart` | `RankingEntry` ya cargados + `roundCount`; falta `finishedAt` / `playerCount` desde `Game` |
| Detalle historial | `history/presentation/pages/game_detail_page.dart` | `GameDetail` (`finalRanking`, `game.finishedAt`, `playerCount`, `roundSequence`) |

**DI:** registrar gateway, renderer (interfaz → impl), use cases y factory del
cubit en `lib/core/di/injection.dart`.

**Fuera de alcance Firebase:** no tocar `data-model.md`, Security Rules ni
datasources Firestore/Auth.

## Implementation Steps

### Step 0: Create Feature Branch

- **Branch:** `feature/LPT-30-mobile`
- **Base:** partir siempre de `develop` (no de `main`).
- Un commit por cada ítem del **Implementation Order** (mensaje en español).
- No implementar en este plan; solo documentar.

### Step 1: Dependencias (`pubspec.yaml`)

- **File:** `app/pubspec.yaml`
- **Action:** Añadir `share_plus` (versión compatible con SDK ^3.12).
- **Notes:** `path_provider` ya está. No añadir HTTP ni Firebase Storage.
- Tras cambio: `flutter pub get`. Documentar la dependencia nueva en
  `mobile-standards.mdc` (paso de documentación).
- **Commit** de este paso al cerrarlo.

### Step 2: Domain — payload y caption (TDD primero)

- **Files:**
  - `lib/features/share_result/domain/entities/share_result_payload.dart`
  - `lib/features/share_result/domain/usecases/build_share_result_caption_usecase.dart`
  - `test/features/share_result/domain/usecases/build_share_result_caption_usecase_test.dart`
- **Signatures (orientativas):**

```dart
class ShareResultPayload {
  const ShareResultPayload({
    required this.ranking,
    required this.finishedAt,
    required this.playerCount,
    required this.roundCount,
  });
  final List<RankingEntry> ranking;
  final DateTime? finishedAt; // null → la card omite la fecha
  final int playerCount;
  final int roundCount;
}

class BuildShareResultCaptionUseCase {
  /// Throws (o Result/error de dominio) si [payload.ranking] está vacío.
  String call(ShareResultPayload payload);
}
```

- **Textos exactos del caption** (tests obligatorios, uno por caso):

| Caso | Caption esperado |
|------|------------------|
| Un ganador (p. ej. María 245) | `La Pocha: gana María con 245 pts` |
| Empate de 2+ en 1º (María, Juan, 245) | `La Pocha: empatan María y Juan con 245 pts` (nombres unidos con comas y `" y "` antes del último) |
| Todos empatados en el mismo puesto/puntos | `La Pocha: empate a 245 pts` |
| Ranking vacío | el use case **rechaza** (no devuelve string); la UI **no muestra** el botón |
| Puntuaciones negativas | se muestran tal cual (p. ej. `… con -10 pts`) |

- **Steps:** tests fallando → implementación → verde.
- **Dependencies:** `RankingEntry` existente (`rank`, `totalScore`, `player`); no
  Flutter/Firebase en domain.
- **Commit** de este paso.

### Step 3: Domain — puertos + use case de share

- **Files:**
  - `lib/features/share_result/domain/entities/share_origin.dart`
  - `lib/features/share_result/domain/repositories/share_sheet_gateway.dart`
  - `lib/features/share_result/domain/repositories/share_result_image_renderer.dart`
  - `lib/features/share_result/domain/usecases/share_game_result_usecase.dart`
  - `test/features/share_result/domain/usecases/share_game_result_usecase_test.dart`

```dart
/// Origen del popover iPad; valores en coordenadas globales (lógicos).
class ShareOrigin {
  const ShareOrigin({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
  final double x, y, width, height;
}

abstract class ShareSheetGateway {
  Future<void> shareImage({
    required String filePath,
    required String caption,
    ShareOrigin? origin, // obligatorio pasar desde UI en iPad (ver Step 4)
  });
}

/// Puerto inyectado en el cubit (no closure en share()).
abstract class ShareResultImageRenderer {
  Future<String> renderPngFile(ShareResultPayload payload);
}

class ShareGameResultUseCase {
  ShareGameResultUseCase(this._gateway);
  final ShareSheetGateway _gateway;

  Future<void> call({
    required String imageFilePath,
    required String caption,
    ShareOrigin? origin,
  });
}
```

- **Conflicto Clean Architecture (explícito):** `share_plus` pide
  `sharePositionOrigin` como `Rect` (Flutter). **No** importar `dart:ui` /
  Flutter en domain. Se modela `ShareOrigin` con primitivos; la impl data
  convierte a `Rect.fromLTWH`. Presentation obtiene el `RenderBox` del botón
  y construye `ShareOrigin`.
- **Notes:** el use case de share no genera la imagen; valida y delega.
  Mock del gateway en unit tests.
- **Commit** de este paso.

### Step 4: Data — implementación `share_plus`

- **File:** `lib/features/share_result/data/share_plus_sheet_gateway.dart`
- **Action:** Implementar `ShareSheetGateway` con la API vigente de
  `share_plus` (`Share.shareXFiles` o equivalente), pasando `XFile` + texto +
  `sharePositionOrigin: Rect.fromLTWH(origin.x, origin.y, origin.width, origin.height)`
  cuando `origin != null`.
- **`sharePositionOrigin` (obligatorio en iPad):** el CTA
  (`ShareResultButton`) lee su `RenderBox` (`context.findRenderObject()` →
  `localToGlobal` + `size`) y pasa `ShareOrigin` al cubit/use case/gateway.
  Sin origen válido, en iPad el share sheet puede fallar o anclarse mal;
  tratar ausencia como error controlado o log + fallo user-facing en iPad.
- **Resultado de `share_plus`:** documentar e implementar el tratamiento de
  `ShareResult` / status de la API usada:
  - éxito / compartido → el cubit emite `ShareResultSuccess`;
  - descartado / cancelado por el usuario → **no** tratar como error de UI
    (volver a `Initial` o `Success` silencioso; preferencia: no snackbar);
  - fallo de plataforma / excepción → `ShareResultFailure` con mensaje en
    español.
  Verificar la API exacta de la versión de `share_plus` al implementarlo
  (el paquete aún no está en `pubspec.yaml`).
- **Fichero temporal:** nombre **fijo** bajo el directorio temporal
  (p. ej. `la_pocha_share_result.png`); cada captura **sobrescribe**.
  **No** hay paso de limpieza/borrado post-share.
- **Notes:** no importar Firebase.
- **Commit** de este paso.

### Step 5: Presentation — card de marca + renderer PNG

- **Files:**
  - `lib/features/share_result/presentation/widgets/share_result_card.dart`
  - `lib/features/share_result/presentation/services/share_result_image_renderer_impl.dart`
  - `test/features/share_result/presentation/services/share_result_image_renderer_impl_test.dart`
    (spike + asserts de tamaño)
  - tests de card bajo `test/features/share_result/presentation/widgets/`

#### Spike / test primero (obligatorio al inicio del step)

- Escribir un test (con `tester.runAsync` donde haga falta) que ejecute el
  renderer con un payload mínimo y demuestre:
  - el fichero PNG existe;
  - tamaño en bytes **> 0**;
  - dimensiones decodificadas **1080×1350**.
- Solo después cerrar el diseño del renderer.

#### Enfoque de captura elegido: (a) árbol de render independiente

- **Elección:** `RenderRepaintBoundary` + `PipelineOwner` + `BuildOwner` +
  `RenderView` (árbol de render aislado).
- **Justificación:**
  - `Offstage` / widgets no pintados **no** producen capas útiles →
    `toImage` falla o queda vacío (descartado).
  - Overlay fuera de pantalla (b) acopla a un `BuildContext`/Overlay vivo y
    complica tests headless; (a) no añade dependencias nuevas y es
  testeable con `runAsync`.
- **Sin paquetes nuevos** (solo Flutter SDK + `path_provider` ya presente).

#### Parámetros de captura

- Tamaño lógico de la card: **360×450**.
- `pixelRatio` fijo **3.0** → salida **1080×1350**, **independiente** de
  `View.of(context).devicePixelRatio` / `MediaQuery.devicePixelRatio`.
- Fichero: nombre fijo (sobrescribe); sin cleanup.

#### ShareResultCard

- Envolver la card en su propio entorno, **sin** depender del tema de la app:
  - `Directionality` (p. ej. `TextDirection.ltr`);
  - `MediaQuery` propio (tamaño 360×450, `textScaler: TextScaler.noScaling`);
  - `DefaultTextStyle` propio (estilos de marca).
- Ignorar escalado de texto del sistema: siempre `TextScaler.noScaling`.
- Marca: preferir widget **`PochaLogo`** (no `Image.asset` directo del PNG).
- Precargar imágenes/fuentes **antes** de capturar (`precacheImage` /
  ensure fonts loaded en el pipeline del renderer).
- Contenido: ganador destacado, ranking (posición desde `RankingEntry.rank`,
  nombre, puntos), fecha **solo si `finishedAt != null`** (si es `null`,
  omitir la fila/fecha), nº jugadores, nº rondas.
- Paleta oscura fija (constantes locales, sin `Theme.of` / `AppTheme`):
  fondo `#1A2420`, tarjeta ganador `#2E5040`, acento menta `#4CAF82`.
  Estructura como resultado final: héroe del ganador + resto (`rank >= 2`).
- Layout robusto 3–8 jugadores; nombres largos sin overflow.

#### Tests específicos de este step

- [ ] `finishedAt == null` → la card **no** muestra fecha.
- [ ] `finishedAt != null` → muestra fecha formateada.
- [ ] Spike PNG no vacío 1080×1350 (ver arriba).

- **Commit** de este paso.

### Step 6: Presentation — Cubit

- **Files:**
  - `lib/features/share_result/presentation/bloc/share_result_cubit.dart`
  - `lib/features/share_result/presentation/bloc/share_result_state.dart`
  - `test/features/share_result/presentation/bloc/share_result_cubit_test.dart`

**Estados:** `ShareResultInitial` | `ShareResultInProgress` |
`ShareResultSuccess` | `ShareResultFailure(message)`.

**Inyección (constructor / getIt), no closure en `share()`:**

```dart
class ShareResultCubit extends Cubit<ShareResultState> {
  ShareResultCubit({
    required BuildShareResultCaptionUseCase buildCaption,
    required ShareResultImageRenderer imageRenderer,
    required ShareGameResultUseCase shareGameResult,
  });

  Future<void> share({
    required ShareResultPayload payload,
    ShareOrigin? origin,
  });
}
```

Flujo: emit InProgress → caption → `imageRenderer.renderPngFile(payload)` →
`ShareGameResultUseCase` (path + caption + origin) → Success / Failure.
Si caption rechaza ranking vacío, Failure (la UI no debería llamar en ese caso).

Mensaje de fallo user-facing en español (patrón
`repeatGameFailureMessage`), p. ej. *"No se pudo compartir. Inténtalo de nuevo."*

- **Commit** de este paso.

### Step 7: Widget CTA reutilizable

- **File:** `lib/features/share_result/presentation/widgets/share_result_button.dart`
- Botón/icono "Compartir" con semantics/tooltip.
- **No renderizar** si `payload.ranking.isEmpty`.
- Obtiene `ShareOrigin` del `RenderBox` del propio botón al pulsar.
- Recibe `ShareResultPayload` + acceso al cubit.
- Loading en `InProgress`; sin doble tap.
- `BlocListener` → snackbar solo en `Failure` (`SnackBarHelper`).
- **Commit** de este paso.

### Step 8: Integrar en resultado final

- **File:** `lib/features/round/presentation/pages/game_final_result_page.dart`
- **Action:**
  1. Extender `_loadFinalResult` / `_FinalResultData` con `finishedAt`,
     `playerCount` (ranking ya existe) desde `Game`.
  2. `finishedAt` puede ser `null`: el payload lo propaga; la card omite fecha
     (mismo contrato Step 5). Añadir/ajustar test que cubra payload con
     `finishedAt: null` desde esta pantalla o fixture equivalente.
  3. Proveer `ShareResultCubit` (getIt factory / `BlocProvider`).
  4. CTA si hay ranking no vacío (AppBar action y/o junto a "Repetir partida").
- Pantalla post-fin → status finished; CTA sujeto a ranking no vacío.
- **Commit** de este paso.

### Step 9: Integrar en detalle de historial

- **File:** `lib/features/history/presentation/pages/game_detail_page.dart`
- **Action:** CTA solo si `detail.game.status == GameStatus.finished` **y**
  ranking no vacío.
- Payload: `finalRanking`, `finishedAt` (nullable → card sin fecha),
  `playerCount`, `roundSequence.length`.
- Test: `finishedAt == null` en detalle → share posible y card sin fecha.
- No compartir partidas en curso / setup.
- **Commit** de este paso.

### Step 10: DI

- **File:** `lib/core/di/injection.dart`
- Registrar: `ShareSheetGateway` → impl, `ShareResultImageRenderer` → impl,
  caption use case, share use case, `ShareResultCubit` (factory).
- **Commit** de este paso.

### Step 11: Update Technical Documentation (mandatory)

1. Revisar diff al cerrar la feature.
2. Actualizar si aplica:
   - `README` (raíz y/o `app/README` según exista) — mencionar compartir
     resultado como imagen / dependencia `share_plus` si el README lista
     capacidades o setup.
   - `ai-specs/specs/data-model.md` — **no** (sin campos nuevos).
   - `ai-specs/specs/mobile-standards.mdc` — anotar `share_plus`, patrón
     “share sheet local sin Firebase”, captura vía árbol de render aislado.
   - `ai-specs/specs/documentation-standards.mdc` — solo si el proceso de docs
     cambia (no esperado).
   - `docs/PRD.md` §9.1 — **ya existe** (`### 9.1 Compartir el resultado de la partida`);
     no requiere cambio salvo desviación de implementación.
3. Documentación en **español**; código en inglés.
4. En el PR: listar ficheros de docs tocados (o confirmar “sin cambios de
   modelo”).
- **Commit** de este paso.

### Step 12: Quality gate

- `dart format` en tocados.
- `flutter analyze --fatal-warnings` limpio en el alcance.
- `flutter test` unit + cubit + widget/renderer de share_result; ajustar
  smoke de páginas si aplica.
- Bump de versión `pubspec.yaml` (patch) según costumbre del repo.
- **Commit** de este paso.

## Implementation Order

Cada línea = un commit (mensajes en español), sobre `feature/LPT-30-mobile`
creada desde **`develop`**:

1. Branch `feature/LPT-30-mobile` desde `develop`
2. Dependencia `share_plus`
3. Domain caption + tests (TDD) — textos exactos Step 2
4. Puertos domain (`ShareOrigin`, gateway, renderer) + use case share + tests
5. Data gateway `share_plus` (`sharePositionOrigin`, resultado ShareResult, fichero fijo)
6. Spike PNG + card + renderer (árbol aislado) + widget tests
7. Cubit + `bloc_test` (renderer inyectado)
8. Botón CTA (`ShareOrigin` desde RenderBox; oculto si ranking vacío)
9. Integración `GameFinalResultPage` (`finishedAt` nullable)
10. Integración `GameDetailPage` (guard `finished` + ranking; `finishedAt` nullable)
11. DI
12. Docs (incl. README) + `flutter analyze --fatal-warnings` + tests + versión

## Testing Checklist

- [ ] Caption: un ganador → `La Pocha: gana María con 245 pts`
- [ ] Caption: empate 2+ → `La Pocha: empatan María y Juan con 245 pts`
- [ ] Caption: todos empatados → `La Pocha: empate a 245 pts`
- [ ] Caption: ranking vacío → use case rechaza; botón no se muestra
- [ ] Caption: puntuaciones negativas tal cual
- [ ] `ShareGameResultUseCase`: delega en gateway con `ShareOrigin`; propaga error
- [ ] Cubit: Initial → InProgress → Success; fallo de render; fallo de share;
      renderer mockeado por interfaz (no closure)
- [ ] Widget: botón visible en final result; visible en detail si finished;
      oculto si no finished o ranking vacío
- [ ] Card: `finishedAt == null` omite fecha; con fecha la muestra
- [ ] **(a)** PNG decodificado **1080×1350** con `tester.runAsync` (bytes > 0)
- [ ] **(b)** Card con `textScaler` al máximo del tester **y** 8 jugadores
      sin overflow (la card de producción usa `TextScaler.noScaling`; el test
      de layout extremo valida robustez del ranking UI)
- [ ] **(c)** Card con empate en 1º: héroe «EMPATE» con todos los empatados
      y lista solo del resto (`rank >= 2`); empate en otros puestos (p. ej.
      dos filas con «3») usando `RankingEntry.rank`; si todos empatan en 1º,
      sin lista de clasificación
- [ ] Manual Android/iOS (incl. iPad anclado con `sharePositionOrigin`)
- [ ] Manual: modo claro y oscuro → imagen idéntica (paleta oscura fija)
- [ ] Manual: avión / sin sesión → funciona
- [ ] `flutter analyze --fatal-warnings` / `flutter test` OK

## Error Handling Patterns

- Cubit emite `ShareResultFailure` con mensaje en español.
- Cancelación del sheet por el usuario ≠ error (sin snackbar).
- UI: `BlocListener` + `SnackBarHelper.showError` solo en fallos reales.
- No silenciar errores de captura PNG o del plugin.
- Evitar estados colgados: siempre salir de `InProgress`.

## UI/UX Considerations

- CTA claro: icono share + tooltip/semantics "Compartir".
- Feedback de progreso durante captura + sheet.
- Imagen autocontenida con `PochaLogo`; sin tema del dispositivo ni
  textScaler del sistema.
- Si `finishedAt` es null, no dejar hueco confuso: omitir bloque de fecha.
- Accesibilidad: contraste en card de marca; botón alcanzable.

## Dependencies

| Paquete | Motivo |
|---------|--------|
| `share_plus` | Share sheet sistema (imagen + texto + origin iPad) |
| `path_provider` (ya existe) | Fichero temporal PNG de nombre fijo |
| `flutter_bloc` / `equatable` (ya existen) | Cubit |

No: Storage, deep links, `http`, feature flags premium, paquetes de screenshot.

## Notes

- Código y tests en **inglés**; plan/docs/commits/PR en **español**.
- Domain sin imports Flutter/Firebase; presentation sin Firebase SDK.
- `ShareOrigin` en domain evita `Rect` de Flutter en la capa de dominio
  (conflicto resuelto explícitamente; no silenciar).
- Share card: paleta oscura de la app (no solo `#2E5040` plano).
- Reutilizar ranking existente; pintar `RankingEntry.rank` (ya expuesto).
- `docs/PRD.md` §9.1 describe aspecto oscuro + héroe/clasificación.
- Un solo ticket: no subtareas Jira desde este plan.
- MCP Atlassian inestable: Jira vía `acli` si hace falta.
- Rama desde **`develop`**; **un commit por paso** del Implementation Order.

## Next Steps After Implementation

1. Abrir PR desde `feature/LPT-30-mobile` → `develop` con checklist manual.
2. Verificación en dispositivo real Android (y iOS/iPad si disponible).
3. Transicionar LPT-30 según workflow del equipo tras review.
4. Opcional: goldens de `ShareResultCard` en CI si se adoptan en el proyecto.

## Implementation Verification

- [ ] Branch `feature/LPT-30-mobile` creada desde `develop`
- [ ] Un commit por paso del Implementation Order
- [ ] Feature `lib/features/share_result/**` con capas correctas
- [ ] CTA en resultado final e historial (solo `finished` + ranking no vacío)
- [ ] PNG 1080×1350 (360×450 @ pixelRatio 3) + caption en share sheet
- [ ] Árbol de render independiente (no Offstage); spike PNG no vacío
- [ ] Fichero temporal de nombre fijo (sin cleanup)
- [ ] `sharePositionOrigin` desde RenderBox del botón
- [ ] Empates coherentes con `RankingEntry.rank` / `RankingService`
- [ ] `finishedAt == null` → sin fecha en la card
- [ ] Paleta oscura fija + `TextScaler.noScaling` + `PochaLogo` / abanico
- [ ] Offline / sin cuenta
- [ ] Sin cambios Firestore / Rules / data-model
- [ ] Tests + `flutter analyze --fatal-warnings` OK
- [ ] Docs actualizadas (incl. README) o explícitamente “N/A”
)
