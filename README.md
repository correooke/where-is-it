# Where Is It

Una aplicación Flutter que permite a los usuarios localizar su vehículo utilizando tecnología Bluetooth y GPS. La aplicación detecta automáticamente cuando el usuario se aleja del vehículo y guarda la ubicación, permitiendo al usuario encontrarlo posteriormente.

## Arquitectura

La aplicación implementa una arquitectura inspirada en Domain-Driven Design (DDD) simplificada, organizada en capas bien definidas para mejorar la mantenibilidad, escalabilidad y testabilidad del código.

### Visión de Alto Nivel

La arquitectura se divide en cuatro capas principales:

1. **Capa de Dominio**: Contiene las entidades centrales de negocio y los contratos de repositorios.
2. **Capa de Infraestructura**: Implementa los repositorios definidos en la capa de dominio.
3. **Capa de Aplicación**: Coordina la lógica de negocio utilizando los servicios y repositorios.
4. **Capa de Presentación**: Contiene la interfaz de usuario y la lógica de presentación.

Adicionalmente, existe una capa de configuración para la inicialización de servicios y permisos.

```
lib/
├── domain/              # Capa de dominio
│   ├── entities/        # Entidades de negocio
│   └── repositories/    # Interfaces de repositorios
├── infrastructure/      # Capa de infraestructura
│   └── repositories/    # Implementaciones de repositorios
├── application/         # Capa de aplicación
│   └── services/        # Servicios de aplicación
│       ├── car_exit_strategy/  # Subsistema de detección de salida
│       │   ├── index.dart      # Archivo barrel para importaciones
│       │   ├── car_exit_detector.dart
│       │   ├── car_exit_detection_strategy.dart
│       │   └── ...             # Implementaciones de estrategias
│       ├── beacon_service.dart
│       └── location_service.dart
├── screens/             # Capa de presentación
├── configuration/       # Configuraciones globales
└── main.dart            # Punto de entrada de la aplicación
```

## Sistema de Detección de Salida de Vehículo

La aplicación implementa un sistema avanzado de detección de salida de vehículo utilizando el patrón Strategy, lo que permite diferentes métodos de detección según la disponibilidad de hardware y permisos.

### Componentes Principales

#### CarExitDetector (Clase Base)

Clase base abstracta que define la interfaz común y la lógica básica para la detección de salida de vehículos:

- **Responsabilidades**:

  - Gestionar múltiples estrategias de detección
  - Mantener el historial de ubicaciones
  - Controlar transiciones de estado
  - Coordinar la selección de la mejor estrategia disponible
  - Mantener estado de monitorización a través del campo `isMonitoring`

- **Métodos protegidos** (accesibles para clases derivadas):
  - `transitionTo`: Maneja las transiciones de estado
  - `startStoppedTimer`: Inicia el temporizador para confirmar detenciones
  - `handleError`: Procesa errores de manera consistente
  - `logMessage`: Sistema de registro unificado

#### CarExitDetectionStrategy (Interfaz)

Interfaz que define el contrato para las estrategias de detección:

- **Métodos clave**:
  - `checkAvailability()`: Verifica si la estrategia puede utilizarse
  - `initialize()`: Prepara la estrategia para su uso
  - `processLocation()`: Procesa nuevas ubicaciones
  - `checkForCarExit()`: Evalúa si se ha producido una salida del vehículo

#### Estrategias de Detección Implementadas

1. **ActivityBasedDetectionStrategy**:

   - Utiliza reconocimiento de actividad del usuario (caminar, correr, en vehículo)
   - Procesa datos de ubicación para determinar velocidad
   - Alta precisión pero mayor consumo de batería

2. **BeaconDetectionStrategy**:
   - Utiliza beacons Bluetooth para detectar proximidad al vehículo
   - Calcula distancia aproximada basada en RSSI
   - Bajo consumo de batería pero requiere hardware adicional

### Máquina de Estados

El sistema utiliza una máquina de estados simple pero efectiva:

- **Estados**:
  - `unknown`: Estado inicial, sin información suficiente
  - `driving`: Usuario dentro del vehículo en movimiento
  - `stopped`: Vehículo detenido, usuario posiblemente aún dentro
  - `exited`: Usuario ha salido del vehículo

### Flujo de Detección

1. Al inicializar, se selecciona la mejor estrategia disponible basada en prioridad
2. La estrategia monitorea actividad/ubicación/beacons según su implementación
3. Al detectar una posible salida, se actualiza el estado y se guarda la ubicación
4. Se notifica al usuario para que pueda localizar su vehículo posteriormente

## Principales Clases (Detallado)

### Capa de Dominio

#### Entidades (`domain/entities/`)

- **`Location`**: Representa una ubicación geográfica.
  - Propiedades: `latitude`, `longitude`, `timestamp`
  - Métodos: `fromLatLng()`, `toLatLng()`, `copyWith()`
  - Responsabilidad: Encapsular los datos de una ubicación y proporcionar conversiones a/desde `LatLng` de Google Maps.

#### Repositorios (`domain/repositories/`)

- **`LocationRepository`**: Interfaz que define operaciones de datos para ubicaciones.

  - Métodos: `getCurrentLocation()`, `saveLocation()`, `loadLastSavedLocation()`
  - Responsabilidad: Definir el contrato para la obtención, guardado y carga de ubicaciones.

- **`BeaconRepository`**: Interfaz para la gestión de beacons Bluetooth.
  - Métodos: `saveBeaconId()`, `loadBeaconId()`
  - Responsabilidad: Persistencia de la información de beacons asociados.

### Capa de Infraestructura

#### Implementaciones de Repositorios (`infrastructure/repositories/`)

- **`LocationRepositoryImpl`**: Implementa `LocationRepository` utilizando servicios externos.
  - Dependencias: `geolocator`, `shared_preferences`
  - Métodos clave:
    - `getCurrentLocation()`: Obtiene la ubicación actual mediante Geolocator.
    - `saveLocation()`: Guarda la ubicación en SharedPreferences.
    - `loadLastSavedLocation()`: Carga la última ubicación guardada.
  - Responsabilidad: Proporcionar la implementación concreta para el acceso a datos de ubicación.

### Capa de Aplicación

#### Servicios (`application/services/`)

- **`CarExitDetector`**: Clase base para la detección de salida de vehículos.

  - Implementa el patrón Strategy para soportar múltiples métodos de detección
  - Mantiene estado interno y coordina transiciones
  - Expone métodos protegidos para facilitar la extensión en clases derivadas

- **`ActivityBasedDetectionStrategy`**: Implementación basada en reconocimiento de actividad.

  - Utiliza `activity_recognition_flutter` para detectar cambios de actividad
  - Procesa datos de ubicación para determinar velocidad y detenciones

- **`BeaconDetectionStrategy`**: Implementación basada en beacons Bluetooth.

  - Utiliza `flutter_blue_plus` para escanear dispositivos cercanos
  - Calcula distancia aproximada basada en RSSI

- **`BeaconService`**: Gestiona operaciones relacionadas con beacons.

  - Métodos: `associateBeacon()`, `getAssociatedBeaconId()`, `dissociateBeacon()`
  - Responsabilidad: Abstraer operaciones con beacons del repositorio.

- **`LocationService`**: Coordina operaciones relacionadas con la ubicación.
  - Dependencias: `LocationRepository`
  - Métodos clave:
    - `getCurrentLocation()`: Obtiene la ubicación actual a través del repositorio.
    - `onExternalTrigger()`: Maneja eventos externos (como la desconexión del Beacon).
    - `saveLocation()`: Guarda una ubicación específica.
    - `loadLastSavedLocation()`: Carga la última ubicación guardada.
  - Responsabilidad: Orquestar la lógica de negocio relacionada con las ubicaciones.

### Capa de Presentación

#### Pantallas (`screens/`)

- **`MapScreen`**: Pantalla principal que muestra el mapa y la ubicación.
  - Dependencias: `GoogleMap`, `LocationService`
  - Funcionalidades clave:
    - Mostrar la ubicación actual y la guardada en el mapa.
    - Permitir al usuario actualizar su ubicación.
    - Simular eventos externos (como la desconexión del Beacon).
  - Responsabilidad: Proporcionar la interfaz de usuario para interactuar con el mapa y ubicaciones.
  - Elementos de interfaz y acciones:
    - **Mapa interactivo de Google**: Muestra la ubicación actual y guardada con marcadores.
      - Al inicializarse llama a `onMapCreated()` que configura el controlador y carga las ubicaciones iniciales.
    - **Botón de ubicación actual** (icono de localización): Actualiza la posición del usuario.
      - Al pulsarlo invoca a `_getCurrentLocation()` y luego `_moveCamera()` para centrar el mapa.
    - **Marcadores en el mapa**:
      - Marcador verde: Ubicación actual del usuario (creado mediante `_addMarker()`).
      - Marcador azul: Ubicación guardada del vehículo (creado mediante `_addMarker()`).

### Configuración

- **`MapConfig`**: Configura la integración con Google Maps.

  - Métodos: `initialize()`
  - Responsabilidad: Inicializar la configuración de Google Maps, especialmente para web.

- **`main.dart`**: Punto de entrada de la aplicación.
  - Inicializa los servicios necesarios.
  - Configura permisos según la plataforma.
  - Renderiza el widget raíz de la aplicación.

## Características Técnicas

### Multiplataforma

La aplicación está diseñada para funcionar tanto en dispositivos móviles como en web:

- **Móvil**: Utiliza `geolocator` para obtener la ubicación precisa y `flutter_blue_plus` para la detección de Beacons Bluetooth.
- **Web**: Implementa adaptaciones específicas para Google Maps en web y manejo alternativo de permisos.

### Organización del Código

El código relacionado con el patrón Strategy para la detección de salida del vehículo está organizado en una subcarpeta dedicada para mejorar la estructura del proyecto:

```
lib/application/services/
├── car_exit_strategy/
│   ├── index.dart                        # Archivo barrel para importaciones
│   ├── car_exit_detector.dart            # Clase base del detector
│   ├── car_exit_detection_strategy.dart  # Interfaz de estrategia
│   ├── activity_based_detection_strategy.dart # Estrategia basada en actividad
│   ├── beacon_detection_strategy.dart    # Estrategia basada en beacons
│   ├── car_exit_state.dart               # Enumeración de estados
│   └── location_info.dart                # Clase para representar ubicaciones
├── beacon_service.dart                   # Servicio relacionado con beacons
├── location_service.dart                 # Servicio relacionado con ubicaciones
└── car_exit_demo.dart                    # Demostración
```

Esta organización proporciona varias ventajas:

- **Mejor cohesión**: Todos los componentes relacionados con el patrón Strategy están agrupados juntos.
- **Simplicidad de importación**: El archivo barrel (`index.dart`) permite importar todos los componentes con una sola línea.
- **Mayor mantenibilidad**: Facilita la gestión y expansión del sistema de detección.
- **Claridad de responsabilidades**: Separa claramente la lógica de detección de salida de otros servicios.
- **Modularidad mejorada**: Permite tratar todo el subsistema de detección como un módulo independiente.
- **Facilidad para pruebas unitarias**: La encapsulación en una subcarpeta facilita el aislamiento de componentes para testing.
- **Reutilización en otros proyectos**: El subsistema completo puede ser extraído y reutilizado en otras aplicaciones.

Para utilizar todo el sistema de detección, solo se necesita importar el archivo barrel:

```dart
import '../application/services/car_exit_strategy/index.dart';
```

Esta estructura soporta los principios SOLID, especialmente el Principio de Segregación de Interfaces y el Principio de Inversión de Dependencias, permitiendo que los componentes interactúen a través de abstracciones bien definidas.

### Patrón Strategy

El uso del patrón Strategy para la detección de salida del vehículo aporta varias ventajas:

- **Flexibilidad**: Permite implementar y combinar diferentes métodos de detección.
- **Degradación elegante**: Si una estrategia no está disponible, se utiliza la siguiente mejor opción.
- **Extensibilidad**: Facilita añadir nuevas estrategias sin modificar el código existente.
- **Mantenibilidad**: La lógica específica se encapsula en clases separadas con responsabilidades claras.

### Almacenamiento de Datos

- Utiliza `shared_preferences` para almacenamiento local persistente de ubicaciones.
- Guarda latitud, longitud y marca de tiempo de las ubicaciones.

### Manejo de Permisos

- Gestiona permisos de ubicación y Bluetooth según la plataforma.
- Implementa verificaciones de permisos antes de acceder a funcionalidades restringidas.

### Integración con Google Maps

- Utiliza `google_maps_flutter` para dispositivos móviles.
- Añade soporte específico con `google_maps_flutter_web` para la versión web.
- Inicializa la API de Google Maps con la clave correspondiente en `index.html`.

## Flujo Principal

1. La aplicación inicia y solicita los permisos necesarios.
2. El detector de salida de vehículo inicializa con la mejor estrategia disponible.
3. Se monitoriza constantemente la actividad del usuario y/o proximidad a beacons.
4. Al detectar que el usuario ha salido del vehículo, se guarda automáticamente la ubicación.
5. El usuario puede visualizar tanto su ubicación actual como la ubicación guardada del vehículo.
6. El sistema de estado proporciona información sobre el estado actual (conduciendo, detenido, salido).
