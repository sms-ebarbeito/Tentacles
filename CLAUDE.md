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

### 2. Detectar sprites dentro de una banda

**Importante:** detectar siempre desde las **últimas filas** de la banda (base), no desde arriba. Algunos sprites tienen partes que sobresalen hacia arriba solapando la banda anterior, lo que confunde la detección.

```python
# Escanear las últimas 15 filas para encontrar gaps entre sprites
col = [sum(1 for y in range(band_y+band_h-15, band_y+band_h) if rows[y][x*4+3] > 5) for x in range(W)]
```

**Casos especiales:**
- **Sprites pegados sin gap** (col_opaque nunca llega a 0): usar grilla cada 10px y pedir al usuario que indique los cortes.
- **Partes del cuerpo que sobresalen lateralmente** (como lenguas, brazos): la detección desde la base puede capturar un gap falso dentro del sprite. Hay que verificar en la zona media del sprite (~40% desde abajo) si hay contenido cruzando el gap.
- **Ruido/saliva/destellos** (píxeles sueltos de 1-3px de ancho): filtrar grupos con `w < 10`.

### 3. Renderizar con grilla para cortes manuales

Cuando la detección automática falla, renderizar con grilla azul cada 10px:

```python
# Grilla azul cada 10px
for gx in range(0, W, 10):
    for py in range(bh):
        idx=(py*bw+gx*scale)*3
        img[idx]=180; img[idx+1]=180; img[idx+2]=255
```

El usuario puede:
- Indicar rangos de bandas: `sprite 1: bandas 1..6` → `x = banda*10 .. (banda_fin+1)*10 - 1`
- Marcar líneas rojas directamente en la imagen y guardarla en `/tmp/`

Para leer marcas rojas del usuario en la imagen (necesita ser gruesas, >3px):
```python
red_xs = set()
for y in range(H):
    for x in range(W):
        r,g,b,a = rows[y][x*4:x*4+4]
        if r > 150 and g < 100 and b < 100 and r > b+80:
            red_xs.add(x)
# Convertir: src_x = round(img_x * 800 / img_W)
```

### 4. Calcular y_top real por sprite

Cada sprite puede tener diferente altura porque la banda anterior puede "sangrar" por arriba. Para cada sprite, buscar la última fila vacía antes del contenido continuo:

```python
def find_ytop(x0, x1, band_start, band_end):
    last_empty = band_start
    for y in range(band_start, band_end):
        has = any(rows[y][x*4+3] > 5 for x in range(x0, x1+1))
        if not has:
            last_empty = y
    return last_empty + 1
# height = band_end - y_top
```

### 5. Preguntar al usuario qué frames usar

Mostrar la imagen con líneas rojas (inicio) y verdes (fin) de cada sprite y preguntar cuáles quiere.

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
