
/// Clase para configuración de mapas en diferentes plataformas
class MapConfig {
  
  /// Inicializa la configuración de Google Maps para web y otras plataformas
  static Future<void> initialize() async {
    // En versiones recientes de google_maps_flutter_web, la inicialización 
    // se maneja automáticamente a través del script en el index.html
    // Por lo tanto, no necesitamos hacer ninguna inicialización adicional aquí
    
    // Podemos añadir más configuraciones para otras plataformas en el futuro
  }
} 