## Preparación

- [x] **Permisos BLE:**  
      Verificar en `AndroidManifest.xml` los permisos:
  ```xml
  <uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
  <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
  ```

## 1. Repositorio de Beacon

- [x] **Agregar persistencia de Beacon ID:**
  - En en un nuevo `BeaconRepositoryImpl`, agregar:
    ```dart
    static const _beaconIdKey = 'beacon_id';
    Future<void> saveBeaconId(String id);
    Future<String?> loadBeaconId();
    ```
  - Utilizar `SharedPreferences` para persistencia local.

## 2. Gestión de Estado en la Pantalla Principal

- [x] **Agregar campo de estado en `MapScreen`:**
  - Definir `String? _selectedBeaconId` en `_MapScreenState`.
  - En `_loadInitialData()`, cargar el ID del beacon desde `SharedPreferences` y asignarlo.

## 3. UI: Botón “Detectar beacon del coche”

- [x] **Mostrar FAB o ítem de menú:**
  - Usar `Icons.bluetooth_searching`.
  - Mostrar solo si `_selectedBeaconId == null` o como opción en Ajustes.

## 4. Configuración de Dependencias

- [x] **Agregar flutter_blue_plus:**
  - En `pubspec.yaml`, incluir:
    ```yaml
    dependencies:
      flutter_blue_plus: ^1.3.0
    ```

## 5. Escaneo BLE

- [x] **Crear método `_startBeaconScan()`:**
  - Iniciar escaneo con:
    ```dart
    FlutterBluePlus.instance.scan(timeout: Duration(seconds: 10))
    ```
  - Acumular dispositivos detectados `{ id, rssi }`.

## 6. UI: Modal de Escaneo

- [ ] **Mostrar progreso de búsqueda:**
  - Usar `showDialog()` con `CircularProgressIndicator` y mensaje “Buscando beacon…”
  - Cerrar el diálogo al finalizar el escaneo.

## 7. Selección y Confirmación del Beacon

- [ ] **Ordenar por RSSI y seleccionar:**

  - Si vacío → mostrar SnackBar “No se encontró ningún beacon.”
  - Si ≥ 1 → seleccionar el de mayor señal.

- [ ] **Mostrar diálogo de confirmación:**
  - Incluir ID y RSSI.
  - Acciones: “Cancelar” y “Confirmar”

## 8. Guardado y Feedback

- [ ] **Persistir el ID del beacon:**
  - Llamar a `saveBeaconId(id)` y actualizar estado con `setState()`.
  - Mostrar SnackBar verde: “Beacon guardado correctamente.”

## 9. Indicador de Conexión

- [ ] **Mostrar estado del beacon:**
  - Si el beacon está en rango → ícono verde.
  - Si no está → ícono gris.
  - Puede integrarse en el FAB o en una barra de estado.

## 10. Lógica de Desconexión

- [ ] **Guardar ubicación al perder señal:**
  - Detectar que el beacon ya no está visible.
  - Llamar a `LocationService.onExternalTrigger()` para guardar ubicación automáticamente.
