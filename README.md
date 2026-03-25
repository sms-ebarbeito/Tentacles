# Buddy - Notification Center Reader

Panel flotante que muestra las notificaciones pendientes del Notification Center de macOS.

## Requisitos

- macOS 26 (Tahoe) o superior
- Xcode Command Line Tools

```bash
xcode-select --install
```

## Compilar y ejecutar

```bash
swiftc buddy.swift -o buddy
./buddy
```

## Uso

- El ícono **🔔** aparece en la barra de menú
- El panel flotante se ubica en la esquina inferior derecha
- Click en 🔔 para mostrar/ocultar el panel
- Se actualiza automáticamente cada 5 segundos
- El número junto al ícono indica cuántas notificaciones hay pendientes

## Cómo funciona

macOS almacena las notificaciones en una base de datos SQLite:

```
~/Library/Group Containers/group.com.apple.usernoted/db2/db
```

> **Nota**: Esta ruta es específica de macOS 26+. En versiones anteriores (hasta Ventura/Sonoma)
> la DB estaba en `~/Library/Application Support/com.apple.notificationcenter/db2/db`.

### Tablas relevantes

| Tabla | Descripción |
|-------|-------------|
| `record` | Notificaciones almacenadas (blob bplist con título, subtítulo, body) |
| `app` | Apps registradas con su bundle ID |
| `delivered` | Control de entrega |

### Estructura del bplist en `record.data`

```
{
  "app"  → bundle ID de la app
  "req"  → {
    "titl" → título
    "subt" → subtítulo
    "body" → cuerpo del mensaje
  }
  "date" → timestamp (referencia: 2001-01-01, Core Data epoch)
}
```

### Consulta base

```sql
SELECT r.rec_id, a.identifier, r.data, r.delivered_date
FROM record r
JOIN app a ON r.app_id = a.app_id
ORDER BY r.delivered_date DESC
LIMIT 50;
```

### Explorar desde terminal

```bash
DB="$HOME/Library/Group Containers/group.com.apple.usernoted/db2/db"

# Ver todas las apps con notificaciones
sqlite3 "$DB" "SELECT DISTINCT a.identifier FROM record r JOIN app a ON r.app_id=a.app_id;"

# Ver las últimas 10 notificaciones
sqlite3 "$DB" "
  SELECT a.identifier, datetime(r.delivered_date + 978307200, 'unixepoch', 'localtime')
  FROM record r JOIN app a ON r.app_id=a.app_id
  ORDER BY r.delivered_date DESC LIMIT 10;"
```

### Decodificar el bplist desde Python

```python
import sqlite3, plistlib, os

DB = os.path.expanduser(
    "~/Library/Group Containers/group.com.apple.usernoted/db2/db"
)

conn = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
rows = conn.execute("""
    SELECT a.identifier, r.data,
           datetime(r.delivered_date + 978307200, 'unixepoch', 'localtime')
    FROM record r
    JOIN app a ON r.app_id = a.app_id
    ORDER BY r.delivered_date DESC
    LIMIT 20
""").fetchall()

for bundle_id, data, fecha in rows:
    pl = plistlib.loads(bytes(data))
    req = pl.get('req', {})
    print(f"[{fecha}] {bundle_id}")
    print(f"  {req.get('titl','')} | {req.get('subt','')}")
    print(f"  {req.get('body','')[:100]}")

conn.close()
```

## Bundle IDs comunes

| App | Bundle ID |
|-----|-----------|
| Slack | `com.tinyspeck.slackmacgap` |
| Mail | `com.apple.mail` |
| Calendario | `com.apple.calendar` |
| Recordatorios | `com.apple.reminders` |
| FaceTime | `com.apple.facetime` |
| Mensajes | `com.apple.mobilesms` |
| Teams | `com.microsoft.teams2` |
| Zoom | `com.zoom.xos` |

## Próximos pasos

- [ ] Muñequito animado que salta y se inquieta con nuevas notificaciones
- [ ] Filtrado por app (mostrar solo Slack, Calendario, etc.)
- [ ] Notificaciones de reuniones destacadas
- [ ] Click en notificación para abrir la app correspondiente
- [ ] Soporte para múltiples pantallas
