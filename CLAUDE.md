# CLAUDE.md — Convenciones del proyecto Buddy

## Workflow para elegir sprites de animación

Cuando hay que cambiar o agregar una animación, el flujo es:

### 1. Detectar bandas del sprite sheet

```python
# Detecta separadores (filas completamente vacías) para encontrar los límites de cada banda
band_starts = [0]
for y in range(H):
    opaque = sum(1 for x in range(W) if rows[y][x*4+3] > 5)
    if opaque == 0:
        if y > 0 and band_starts[-1] != y:
            prev_op = sum(1 for x in range(W) if rows[y-1][x*4+3] > 5)
            if prev_op > 0:
                band_starts.append(y)
```

Esto imprime algo como:
```
banda 0: y=0..67
banda 1: y=67..150
banda 8: y=664..761
...
```

### 2. Renderizar una banda con líneas de corte

Dado el número de banda, renderizarla a escala 4x con fondo blanco y líneas rojas marcando cada sprite:

```python
# Detectar sprites (grupos de columnas con píxeles opacos)
col_opaque = [sum(1 for y in range(band_y, band_y+band_h) if rows[y][x*4+3] > 5) for x in range(W)]
sprites = []
in_sprite = False
for x in range(W):
    if col_opaque[x] > 0 and not in_sprite:
        sx = x; in_sprite = True
    elif col_opaque[x] == 0 and in_sprite:
        sprites.append((sx, x-1)); in_sprite = False

# Renderizar a 4x con líneas rojas en los bordes de cada sprite
# Guardar como /tmp/bandN.ppm y abrir con: qlmanage -t -s 3200 /tmp/bandN.ppm -o /tmp/ && open /tmp/bandN.ppm.png
```

### 3. Preguntar al usuario qué frames usar

Mostrarle la imagen con los sprites numerados `[0]`, `[1]`, ... y preguntar cuáles quiere para la animación.

### 4. Actualizar Sprite.swift

Con los frames elegidos, actualizar `Sprite.crazy` (u otra animación) en `Sources/BuddyApp/Sprite.swift`:

```swift
static let crazy: [CGRect] = [
    CGRect(x: x0, y: band_y, width: w0, height: band_h),
    CGRect(x: x1, y: band_y, width: w1, height: band_h),
    // ...
]
```

### 5. Compilar y ejecutar

```bash
swift build && pkill -f BuddyApp; .build/arm64-apple-macosx/debug/BuddyApp &
```

**Importante:** usar `swift build` sin `--target` — con `--target BuddyApp` compila pero no linkea el ejecutable.

---

## Estructura del PNG

- `tentacles-sprites.png` en `Sources/BuddyApp/Resources/`
- 800×1553 px, RGBA (4 bytes por píxel)
- ~20 bandas horizontales separadas por filas vacías
- El decoder PNG manual maneja los 5 filtros (0=None, 1=Sub, 2=Up, 3=Average, 4=Paeth)

## Coordenadas en OctopusView

- `NSImage` tiene y=0 abajo; el PNG tiene y=0 arriba → fórmula de flip:
  ```swift
  flipped.y = sheet.size.height - rect.maxY
  ```
- Los sprites se dibujan a escala 2x, anclados a la base de la ventana (`y=0`)
- `Sprite.displaySize = CGSize(width: 160, height: 200)`
