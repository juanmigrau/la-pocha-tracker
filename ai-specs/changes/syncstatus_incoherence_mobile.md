# Mobile Implementation Plan: syncStatus incoherence (historial vs detalle)

## Overview

Corregir la incoherencia del chip/badge de sincronización entre
`history_list_page` y `game_detail_page`, y asegurar que el reintento
(manual/automático) opere sobre partidas con `syncStatus` correcto
(`pending` / `failed` → `synced`).

## Architecture Context

- Feature sync: `UploadFinishedGameUseCase`, `RetryPendingUploadsUseCase`,
  `GameSyncRepositoryImpl`
- Feature history: `HistoryListBloc`, `GameDetailBloc`, mappers/tiles
- Persistencia local: Drift `games.syncStatus` / `cloudGameId`

## Diagnóstico (PASO 1 — estático; validar con logs runtime)

### 1. `game_detail_page` — ¿cómo recibe el Game?

**No usa el objeto Game de navegación.** Recibe `gameId` + `source`
(query `?source=`). Al entrar dispara `GameDetailStarted` →
`GetGameDetailUseCase` → Drift (si `source == local`) o Firestore (si cloud).

**Pero el badge "Local/Nube" usa `detail.source` (parámetro de ruta), no
`game.syncStatus`.** Tras sync exitoso, Drift puede tener `synced` y el
detalle sigue mostrando "Local" si se abrió con `source=local`.

### 2. `history_list_page` — ¿cómo lee syncStatus?

Desde el **estado del BLoC** (`HistoryListLoaded.items`), alimentado por
`GetGameHistoryUseCase.watch()` → Drift watch + merge con nube.
El chip en `GameHistoryTile` usa `item.syncStatus` para pending/failed;
si no, `item.source` para Local/Nube. `fromLocalGame` fija siempre
`source: local` aunque `syncStatus == synced`.

### 3. Flujo sync tras `RetryPendingUploadsUseCase`

Tras `batch.commit` exitoso, `GameSyncRepositoryImpl` **sí** llama
`updateSyncMetadata(..., syncStatus: synced)`. El historial se refresca
vía watch Drift (no hay evento BLoC explícito de “reload tras sync”).

### Hipótesis a confirmar con runtime

| Id | Hipótesis |
|----|-----------|
| H1 | `finishGame` deja `syncStatus=local`; si la subida no marca `pending`, no hay botón de reintento ni retry automático |
| H2 | Detalle muestra badge por `source` de ruta (stale), no por `syncStatus` de Drift |
| H3 | Historial con `synced` + `source=local` muestra "Local" hasta dedup nube |
| H4 | `getPendingGames` solo consulta `pending`/`failed`, ignora `local` |
| H5 | Tras retry OK, Drift queda `synced` pero UI detalle no refleja sync |

## Implementation Steps (PASO 2 — solo tras evidencia)

### Step 1: Corregir transición `local` → `pending` al fallar/offline

- Asegurar que tras finalizar, si no hay sync completa, Drift quede en
  `pending` (nunca quedarse en `local` tras intento de upload fallido
  o sin red). Revisar `finishGame` + `UploadFinishedGameUseCase` /
  `skippedNoSession` si aplica.

### Step 2: Badge de detalle coherente con syncStatus

- En detalle local, derivar badge de `game.syncStatus` / `cloudGameId`
  (p. ej. `synced` → Nube; `pending`/`failed` → pendiente; resto Local),
  no solo del query `source`.

### Step 3: Chip historial coherente con syncStatus

- Si `syncStatus == synced` (aunque `source == local`), mostrar "Nube".
- Mantener reintento solo para `pending`/`failed`.

### Step 4: Retry incluye estados correctos

- Confirmar que `RetryPendingUploads` sigue cubriendo `pending`+`failed`
  y que no queden juegos "huérfanos" en `local` tras un intento.

### Step 5: Version + quality

- `pubspec.yaml` patch +1
- `flutter analyze` limpio
- Tests existentes/ajustados en tile/mapper/upload

## Testing Checklist

- [ ] Offline finish → Drift `pending` + chip reintento
- [ ] Online retry → `synced` + chip Nube en lista y detalle
- [ ] Botón reintento visible solo con `pending`/`failed`
- [ ] `flutter analyze` / tests sync+history

## Notes

- Fix aplicado: `finishGame` → `pending`; UI chips/badge según `syncStatus`;
  `getPendingGames` incluye `local` finished huérfanos; upload promueve
  `local` → `pending` antes del intento.
- Código en inglés; commits/docs en español.
