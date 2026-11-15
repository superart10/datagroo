import 'package:datagroo/core/l10n/app_language.dart';

/// Índice Específico de Aptitud de Cultivo (IEAC).
/// [p], [t] y [a] son puntajes (0 a 100) para precipitación, temperatura y variable agronómica.
double calcularIEAC(double p, double t, double a) {
  return (0.35 * p) + (0.35 * t) + (0.30 * a);
}

/// Convierte lecturas crudas en el puntaje 0-100 que espera [calcularIEAC].
double componenteAptitud(double valor, double? minimo, double? maximo) {
  if (minimo == null || maximo == null || maximo <= minimo) {
    return 80.0;
  }
  if (valor >= minimo && valor <= maximo) {
    final mid = (minimo + maximo) / 2;
    final half = (maximo - minimo) / 2;
    final cercania = 1 - ((valor - mid).abs() / half);
    return 70.0 + (30.0 * cercania);
  }
  final distancia = valor < minimo ? minimo - valor : valor - maximo;
  final span = maximo - minimo;
  final penalizacion = (distancia / span) * 100;
  return (70.0 - penalizacion).clamp(0.0, 100.0);
}

class CompatibilidadCultivo {
  /// Verdadero si la temperatura está dentro del rango ideal del cultivo.
  final bool favorable;
  final String recomendacion;

  const CompatibilidadCultivo({
    required this.favorable,
    required this.recomendacion,
  });

  /// Etiqueta del estado en el idioma activo.
  String get estado => favorable ? tr('Favorable', 'Favorable') : tr('Requiere atención', 'Needs attention');
}

/// Compara la temperatura actual con el rango ideal del cultivo de la parcela.
/// Devuelve si es favorable y una recomendación directa, en el idioma activo.
CompatibilidadCultivo evaluarCompatibilidad({
  required double temperaturaC,
  required String cultivo,
  double? tempMin,
  double? tempMax,
}) {
  if (tempMin == null || tempMax == null) {
    return CompatibilidadCultivo(
      favorable: false,
      recomendacion: tr(
        'No hay rango de temperatura registrado para $cultivo.',
        'There is no temperature range on record for $cultivo.',
      ),
    );
  }

  final dentro = temperaturaC >= tempMin && temperaturaC <= tempMax;
  final rango = '${tempMin.toStringAsFixed(0)}°C ${tr('a', 'to')} ${tempMax.toStringAsFixed(0)}°C';
  if (dentro) {
    return CompatibilidadCultivo(
      favorable: true,
      recomendacion: tr(
        '$cultivo se mantiene dentro de su rango ideal ($rango).',
        '$cultivo stays within its ideal range ($rango).',
      ),
    );
  }
  return CompatibilidadCultivo(
    favorable: false,
    recomendacion: tr(
      'La temperatura actual (${temperaturaC.toStringAsFixed(0)}°C) está fuera del rango ideal para $cultivo ($rango).',
      'The current temperature (${temperaturaC.toStringAsFixed(0)}°C) is outside the ideal range for $cultivo ($rango).',
    ),
  );
}
