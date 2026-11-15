import 'package:datagroo/core/l10n/app_language.dart';

/// Traduce al inglés los textos del catálogo que vienen de la base de datos
/// (cultivos y regiones sembrados en `database_helper.dart`).
///
/// La base de datos guarda todo en español; la traducción se hace solo al
/// mostrar. Un texto que no esté en la tabla (por ejemplo, uno escrito por el
/// usuario) se muestra tal cual.
String trDb(String? text) {
  if (text == null) return '';
  if (!AppLanguage.isEnglish) return text;
  final found = _catalogEn[text];
  if (found != null) return found;
  // Rangos de temperatura: "14°C a 28°C" -> "14°C to 28°C"
  if (_tempRange.hasMatch(text)) return text.replaceFirst(' a ', ' to ');
  return text;
}

/// Igual que [trDb], pero devuelve `null` si el valor de la base de datos es
/// nulo, para poder escribir `trDbOrNull(fila['campo']) ?? 'valor por defecto'`.
String? trDbOrNull(Object? value) => value == null ? null : trDb(value.toString());

/// Verdadero si [query] aparece en el texto original o en su traducción.
bool matchesCatalogText(String? text, String query) {
  if (text == null) return false;
  final q = query.toLowerCase();
  return text.toLowerCase().contains(q) || trDb(text).toLowerCase().contains(q);
}

final RegExp _tempRange = RegExp(r'^\d+°C a \d+°C$');

const Map<String, String> _catalogEn = {
  // Regiones
  'Veracruz Norte': 'Northern Veracruz',
  'Veracruz Centro': 'Central Veracruz',
  'Veracruz Sur': 'Southern Veracruz',

  // Nombres de cultivos
  'Café': 'Coffee',
  'Maíz criollo': 'Native corn',
  'Frijol': 'Beans',
  'Calabaza o calabacita': 'Squash or zucchini',
  'Piña': 'Pineapple',
  'Chile jalapeño': 'Jalapeño pepper',
  'Papa': 'Potato',
  'Avena forrajera': 'Forage oats',

  // Tipos de cultivo
  'Perenne': 'Perennial',
  'Anual': 'Annual',
  'Anual de ciclo corto': 'Short-cycle annual',
  'Anual de ciclo medio': 'Medium-cycle annual',
  'Semiperenne': 'Semi-perennial',
  'Herbáceo perenne': 'Herbaceous perennial',

  // Requerimiento de agua
  'Entre 1,400 y 2,300 mm de lluvia al año': 'Between 1,400 and 2,300 mm of rain per year',
  'Humedad de temporal o tonamil': 'Moisture from the rainy season or the winter (tonamil) cycle',
  'Humedad residual y temporal': 'Residual and rainy-season moisture',
  '350 a 500 mm acumulados por ciclo': '350 to 500 mm accumulated per cycle',
  '1000 a 1500 mm al año': '1000 to 1500 mm per year',
  '450 a 650 mm acumulados': '450 to 650 mm accumulated',
  '600 a 800 mm acumulados': '600 to 800 mm accumulated',
  '350 a 500 mm acumulados': '350 to 500 mm accumulated',

  // Tipo de suelo
  'Suelos volcánicos profundos, sueltos y con buen drenaje. pH 5.5 a 7':
      'Deep, loose volcanic soils with good drainage. pH 5.5 to 7',
  'Textura franca a franco-arcillosa. pH 5 a 7': 'Loam to clay-loam texture. pH 5 to 7',
  'Suelos francos, franco-arcillosos o aluviales. pH 5.5 a 7.5':
      'Loam, clay-loam or alluvial soils. pH 5.5 to 7.5',
  'Abono y fertilizantes ricos en N, P, K. pH 5.5 a 6.8':
      'Compost and fertilizers rich in N, P, K. pH 5.5 to 6.8',
  'Suelos francos o franco-arenosos profundos. pH 4.5 a 8': 'Deep loam or sandy-loam soils. pH 4.5 to 8',
  'Suelos francos o franco-arenosos sueltos. pH 5.5 a 6.8': 'Loose loam or sandy-loam soils. pH 5.5 to 6.8',
  'Suelos volcánicos andosoles de textura franca. pH 5.5 a 6.8':
      'Volcanic andosol soils with loam texture. pH 5.5 to 6.8',
  'Suelos francos, profundos y bien drenados. pH 5.5 a 7': 'Deep, well-drained loam soils. pH 5.5 to 7',

  // Descripciones
  'Arbusto perenne. Empieza a producir a los 3 o 4 años y su vida útil suele ser de 20 a 30 años.':
      'Perennial shrub. It starts producing after 3 or 4 years and its productive life is usually 20 to 30 years.',
  'Maíz anual de 3 a 7 meses, adaptado al centro y sur de Veracruz.':
      'Annual corn with a 3 to 7 month cycle, adapted to central and southern Veracruz.',
  'Leguminosa de ciclo corto, de 70 a 95 días.': 'Short-cycle legume, 70 to 95 days.',
  'Cultivo anual de 45 a 90 días con alta compatibilidad con maíz y frijol.':
      'Annual crop of 45 to 90 days, highly compatible with corn and beans.',
  'Cultivo semiperenne de 14 a 18 meses para la primera cosecha.':
      'Semi-perennial crop that takes 14 to 18 months to the first harvest.',
  'Cultivo anual de 4 a 6 meses con excelente compatibilidad con maíz y sorgo.':
      'Annual crop of 4 to 6 months, with excellent compatibility with corn and sorghum.',
  'Tubérculo de clima templado-frío en regiones de altura de Veracruz.':
      'Tuber for cool-temperate climates in the highland regions of Veracruz.',
  'Cereal forrajero anual de 80 a 100 días para zonas del centro de Veracruz.':
      'Annual forage cereal of 80 to 100 days for areas of central Veracruz.',

  // Recomendaciones de rotación
  'No se rota como cultivo anual. Evitar cultivos que agoten el potasio.':
      'It is not rotated like an annual crop. Avoid crops that deplete potassium.',
  'Alternar con leguminosas o tubérculos. Evitar sembrar maíz tras maíz.':
      'Alternate with legumes or tubers. Avoid planting corn after corn.',
  'No repetir frijol ni otra leguminosa en 2 o 3 años. Rotar con maíz, sorgo, arroz o caña.':
      'Do not repeat beans or another legume for 2 or 3 years. Rotate with corn, sorghum, rice or sugarcane.',
  'Esperar entre 2 o 3 años antes de volver a sembrar calabaza.':
      'Wait 2 to 3 years before planting squash again.',
  'Esperar al menos 1 o 2 años antes de volver a sembrar piña.':
      'Wait at least 1 or 2 years before planting pineapple again.',
  'Esperar un mínimo de 3 a 4 años para volver a sembrarlo.': 'Wait a minimum of 3 to 4 years before planting it again.',
  'En zonas altas se rota cada 2 o 3 años para controlar plagas.':
      'In highland areas it is rotated every 2 or 3 years to control pests.',
  'Excelente cultivo limpiador y protector del suelo si se rota cada 1 o 2 años.':
      'An excellent cleaning and soil-protecting crop when rotated every 1 or 2 years.',
};
