import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';

/// Repositório de bairros favoritos
class FavoritesRepository {
  final SharedPreferences _prefs;

  static const _favoritesKey = 'favorite_neighborhoods';

  FavoritesRepository(this._prefs);

  /// Lista de bairros favoritos
  List<String> get favorites {
    return _prefs.getStringList(_favoritesKey) ?? [];
  }

  /// Adiciona um bairro aos favoritos
  Future<void> addFavorite(String neighborhood) async {
    final current = favorites;
    if (!current.contains(neighborhood)) {
      current.add(neighborhood);
      await _prefs.setStringList(_favoritesKey, current);
    }
  }

  /// Remove um bairro dos favoritos
  Future<void> removeFavorite(String neighborhood) async {
    final current = favorites;
    current.remove(neighborhood);
    await _prefs.setStringList(_favoritesKey, current);
  }

  /// Define todos os favoritos
  Future<void> setFavorites(List<String> neighborhoods) async {
    await _prefs.setStringList(_favoritesKey, neighborhoods);
  }

  /// Limpa todos os favoritos
  Future<void> clearFavorites() async {
    await _prefs.remove(_favoritesKey);
  }

  /// Verifica se um bairro é favorito
  bool isFavorite(String neighborhood) {
    return favorites.contains(neighborhood);
  }
}

/// Provider do repositório
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FavoritesRepository(prefs);
});

/// Lista de bairros do Rio de Janeiro (para sugestões)
const rioNeighborhoods = [
  'Abolição',
  'Acari',
  'Alto da Boa Vista',
  'Anchieta',
  'Andaraí',
  'Anil',
  'Bangu',
  'Barra da Tijuca',
  'Barra de Guaratiba',
  'Barros Filho',
  'Bento Ribeiro',
  'Bonsucesso',
  'Botafogo',
  'Brás de Pina',
  'Cachambi',
  'Cacuia',
  'Caju',
  'Camorim',
  'Campinho',
  'Campo Grande',
  'Campo dos Afonsos',
  'Cascadura',
  'Catete',
  'Catumbi',
  'Cavalcanti',
  'Centro',
  'Cidade Nova',
  'Cidade Universitária',
  'Cocotá',
  'Coelho Neto',
  'Colégio',
  'Complexo do Alemão',
  'Copacabana',
  'Cordovil',
  'Cosme Velho',
  'Costa Barros',
  'Curicica',
  'Del Castilho',
  'Deodoro',
  'Encantado',
  'Engenheiro Leal',
  'Engenho da Rainha',
  'Engenho de Dentro',
  'Engenho Novo',
  'Estácio',
  'Flamengo',
  'Freguesia (Ilha)',
  'Freguesia (Jacarepaguá)',
  'Galeão',
  'Gamboa',
  'Gardênia Azul',
  'Gávea',
  'Glória',
  'Grajaú',
  'Grumari',
  'Guadalupe',
  'Guaratiba',
  'Higienópolis',
  'Honório Gurgel',
  'Humaitá',
  'Inhaúma',
  'Inhoaíba',
  'Ipanema',
  'Irajá',
  'Itanhangá',
  'Jacaré',
  'Jacarepaguá',
  'Jacarezinho',
  'Jardim América',
  'Jardim Botânico',
  'Jardim Carioca',
  'Jardim Guanabara',
  'Jardim Sulacap',
  'Joá',
  'Lagoa',
  'Laranjeiras',
  'Leblon',
  'Leme',
  'Lins de Vasconcelos',
  'Madureira',
  'Magalhães Bastos',
  'Mangueira',
  'Manguinhos',
  'Maracanã',
  'Maré',
  'Marechal Hermes',
  'Maria da Graça',
  'Méier',
  'Moneró',
  'Olaria',
  'Oswaldo Cruz',
  'Paciência',
  'Padre Miguel',
  'Paquetá',
  'Parada de Lucas',
  'Parque Anchieta',
  'Parque Columbia',
  'Pavuna',
  'Pechincha',
  'Pedra de Guaratiba',
  'Penha',
  'Penha Circular',
  'Piedade',
  'Pilares',
  'Pitangueiras',
  'Portuguesa',
  'Praça da Bandeira',
  'Praça Seca',
  'Praia da Bandeira',
  'Quintino Bocaiúva',
  'Ramos',
  'Realengo',
  'Recreio dos Bandeirantes',
  'Riachuelo',
  'Ribeira',
  'Ricardo de Albuquerque',
  'Rio Comprido',
  'Rocha',
  'Rocha Miranda',
  'Rocinha',
  'Sampaio',
  'Santa Cruz',
  'Santa Teresa',
  'Santíssimo',
  'Santo Cristo',
  'São Conrado',
  'São Cristóvão',
  'São Francisco Xavier',
  'Saúde',
  'Senador Camará',
  'Senador Vasconcelos',
  'Sepetiba',
  'Tanque',
  'Taquara',
  'Tauá',
  'Tijuca',
  'Todos os Santos',
  'Tomás Coelho',
  'Turiaçu',
  'Urca',
  'Vargem Grande',
  'Vargem Pequena',
  'Vasco da Gama',
  'Vaz Lobo',
  'Vicente de Carvalho',
  'Vidigal',
  'Vigário Geral',
  'Vila Cosmos',
  'Vila da Penha',
  'Vila Isabel',
  'Vila Kosmos',
  'Vila Militar',
  'Vila Valqueire',
  'Vista Alegre',
  'Zumbi',
];
