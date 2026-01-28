import 'package:flutter/material.dart';

/// Estágio da Cidade - Classificação oficial do COR
///
/// Os estágios são numerados de 1 a 5, indicando o nível de
/// impacto das ocorrências na cidade do Rio de Janeiro.
enum CityStage {
  stage1, // Sem ocorrências significativas
  stage2, // Risco de ocorrências de alto impacto
  stage3, // Ocorrências impactando a cidade
  stage4, // Ocorrências graves impactando a cidade
  stage5, // Múltiplas ocorrências graves - capacidade extrapolada
}

/// Extensão com dados oficiais do Estágio da Cidade
extension CityStageExtension on CityStage {
  /// Número do estágio (1-5)
  int get number {
    switch (this) {
      case CityStage.stage1:
        return 1;
      case CityStage.stage2:
        return 2;
      case CityStage.stage3:
        return 3;
      case CityStage.stage4:
        return 4;
      case CityStage.stage5:
        return 5;
    }
  }

  /// Label para exibição
  String get label => 'Estágio $number';

  /// Label completo (mesmo que label, pois estágios não têm mais nomes)
  String get fullLabel => 'Estágio $number';

  /// Cor oficial do estágio
  Color get color {
    switch (this) {
      case CityStage.stage1:
        return const Color(0xFF4CAF50); // Verde
      case CityStage.stage2:
        return const Color(0xFFFFEB3B); // Amarelo
      case CityStage.stage3:
        return const Color(0xFFFF9800); // Laranja
      case CityStage.stage4:
        return const Color(0xFFF44336); // Vermelho
      case CityStage.stage5:
        return const Color(0xFF9C27B0); // Roxo
    }
  }

  /// Cor do texto sobre o badge
  Color get textColor {
    switch (this) {
      case CityStage.stage1:
      case CityStage.stage4:
      case CityStage.stage5:
        return Colors.white;
      case CityStage.stage2:
      case CityStage.stage3:
        return Colors.black87;
    }
  }

  /// Descrição oficial de quando é ativado (fonte: COR)
  String get whenActivated {
    switch (this) {
      case CityStage.stage1:
        return 'Não há ocorrências que provoquem alteração significativa no dia a dia do carioca. Não foram identificados fatores de risco de curto prazo que impactem a rotina da cidade.';
      case CityStage.stage2:
        return 'Risco de haver ocorrências de alto impacto na cidade devido a um evento previsto ou a partir da análise de dados.';
      case CityStage.stage3:
        return 'Uma ou mais ocorrências estão impactando a cidade. Há certeza de que haverá ocorrência de alto impacto, no curto prazo.';
      case CityStage.stage4:
        return 'Uma ou mais ocorrências graves impactam a cidade ou há incidência simultânea de diversos problemas de médio e alto impacto em diferentes regiões da cidade.';
      case CityStage.stage5:
        return 'Uma ou mais ocorrências graves impactam a cidade ou há incidência simultânea de diversos problemas de médio e alto impacto em diferentes regiões da cidade. Os múltiplos danos e impactos causados extrapolam de forma relevante a capacidade de resposta imediata das equipes da cidade.';
    }
  }

  /// Descrição oficial do impacto (fonte: COR)
  String get impact {
    switch (this) {
      case CityStage.stage1:
        return 'Sem ou com pouco impacto para a fluidez do trânsito e das operações de infraestrutura e logística da cidade.';
      case CityStage.stage2:
        return 'Há risco de impactos, ou já foram identificados impactos, em pelo menos uma região da cidade.';
      case CityStage.stage3:
        return 'Pelo menos uma região da cidade está impactada, causando reflexos relevantes na infraestrutura e logística urbana.';
      case CityStage.stage4:
        return 'Uma ou mais regiões da cidade estão impactadas, causando reflexos graves/importantes na infraestrutura e logística urbana.';
      case CityStage.stage5:
        return 'Uma ou mais regiões da cidade estão impactadas, afetando severamente a rotina da população na cidade.';
    }
  }

  /// Ícone representativo
  IconData get icon {
    switch (this) {
      case CityStage.stage1:
        return Icons.check_circle_outline;
      case CityStage.stage2:
        return Icons.info_outline;
      case CityStage.stage3:
        return Icons.warning_amber_outlined;
      case CityStage.stage4:
        return Icons.error_outline;
      case CityStage.stage5:
        return Icons.dangerous_outlined;
    }
  }

  /// Caminho da imagem do estágio
  /// Imagens devem ser colocadas em: assets/images/stages/
  /// Nomes: stage_1.png, stage_2.png, stage_3.png, stage_4.png, stage_5.png
  String get imagePath => 'assets/images/stages/stage_$number.png';

  /// Cria a partir do número (1-5)
  static CityStage fromNumber(int number) {
    switch (number) {
      case 1:
        return CityStage.stage1;
      case 2:
        return CityStage.stage2;
      case 3:
        return CityStage.stage3;
      case 4:
        return CityStage.stage4;
      case 5:
        return CityStage.stage5;
      default:
        return CityStage.stage1;
    }
  }
}

/// Nível de Calor - Classificação oficial do COR
enum HeatLevel {
  nc1, // Normal
  nc2, // Atenção
  nc3, // Alerta
  nc4, // Crítico
  nc5, // Emergência
}

/// Extensão com dados oficiais do Nível de Calor
extension HeatLevelExtension on HeatLevel {
  /// Número do nível (1-5)
  int get number {
    switch (this) {
      case HeatLevel.nc1:
        return 1;
      case HeatLevel.nc2:
        return 2;
      case HeatLevel.nc3:
        return 3;
      case HeatLevel.nc4:
        return 4;
      case HeatLevel.nc5:
        return 5;
    }
  }

  /// Nome oficial do nível
  String get name {
    switch (this) {
      case HeatLevel.nc1:
        return 'Normal';
      case HeatLevel.nc2:
        return 'Atenção';
      case HeatLevel.nc3:
        return 'Alerta';
      case HeatLevel.nc4:
        return 'Crítico';
      case HeatLevel.nc5:
        return 'Emergência';
    }
  }

  /// Label curto para exibição
  String get label => 'NC$number';

  /// Label completo
  String get fullLabel => 'NC$number – $name';

  /// Cor oficial do nível de calor
  Color get color {
    switch (this) {
      case HeatLevel.nc1:
        return const Color(0xFF2196F3); // Azul
      case HeatLevel.nc2:
        return const Color(0xFF4CAF50); // Verde
      case HeatLevel.nc3:
        return const Color(0xFFFFEB3B); // Amarelo
      case HeatLevel.nc4:
        return const Color(0xFFFF9800); // Laranja
      case HeatLevel.nc5:
        return const Color(0xFFB71C1C); // Vermelho escuro
    }
  }

  /// Cor do texto sobre o badge
  Color get textColor {
    switch (this) {
      case HeatLevel.nc1:
      case HeatLevel.nc4:
      case HeatLevel.nc5:
        return Colors.white;
      case HeatLevel.nc2:
        return Colors.white;
      case HeatLevel.nc3:
        return Colors.black87;
    }
  }

  /// Faixa de temperatura
  String get temperatureRange {
    switch (this) {
      case HeatLevel.nc1:
        return '< 36°C';
      case HeatLevel.nc2:
        return '36°C – 40°C (1-2 dias)';
      case HeatLevel.nc3:
        return '36°C – 40°C (≥ 3 dias)';
      case HeatLevel.nc4:
        return '40°C – 44°C';
      case HeatLevel.nc5:
        return '> 44°C';
    }
  }

  /// Descrição oficial de quando é ativado
  String get whenActivated {
    switch (this) {
      case HeatLevel.nc1:
        return 'Temperaturas abaixo de 36°C. Condições térmicas normais para a cidade.';
      case HeatLevel.nc2:
        return 'Temperaturas entre 36°C e 40°C previstas por 1 a 2 dias consecutivos.';
      case HeatLevel.nc3:
        return 'Temperaturas entre 36°C e 40°C previstas por 3 ou mais dias consecutivos (onda de calor).';
      case HeatLevel.nc4:
        return 'Temperaturas entre 40°C e 44°C. Calor extremo com risco à saúde.';
      case HeatLevel.nc5:
        return 'Temperaturas acima de 44°C. Situação excepcional de calor extremo.';
    }
  }

  /// Ações recomendadas
  String get recommendedActions {
    switch (this) {
      case HeatLevel.nc1:
        return '• Mantenha-se hidratado\n• Use protetor solar\n• Evite exposição prolongada ao sol entre 10h e 16h';
      case HeatLevel.nc2:
        return '• Aumente a ingestão de água\n• Evite exercícios físicos intensos ao ar livre\n• Procure locais com ar-condicionado\n• Atenção especial a idosos e crianças';
      case HeatLevel.nc3:
        return '• Beba água constantemente, mesmo sem sede\n• Evite sair de casa entre 10h e 16h\n• Verifique idosos, crianças e pessoas com doenças crônicas\n• Equipamentos públicos de refrigeração podem ser ativados';
      case HeatLevel.nc4:
        return '• Permaneça em locais refrigerados\n• Hidrate-se intensamente\n• Evite qualquer atividade física ao ar livre\n• Pontos de hidratação e abrigos climatizados são ativados\n• Procure atendimento médico se sentir mal-estar';
      case HeatLevel.nc5:
        return '• Situação de emergência - evite sair de casa\n• Mantenha-se em local refrigerado\n• Hidrate-se constantemente\n• Abrigos climatizados de emergência são abertos\n• Ligue 199 (Defesa Civil) em caso de emergência\n• Procure atendimento médico imediatamente se necessário';
    }
  }

  /// Ícone representativo
  IconData get icon {
    switch (this) {
      case HeatLevel.nc1:
        return Icons.thermostat_outlined;
      case HeatLevel.nc2:
        return Icons.wb_sunny_outlined;
      case HeatLevel.nc3:
        return Icons.wb_sunny;
      case HeatLevel.nc4:
        return Icons.local_fire_department_outlined;
      case HeatLevel.nc5:
        return Icons.local_fire_department;
    }
  }

  /// Caminho da imagem do nível de calor
  /// Imagens devem ser colocadas em: assets/images/heat_levels/
  /// Nomes: nc_1.png, nc_2.png, nc_3.png, nc_4.png, nc_5.png
  String get imagePath => 'assets/images/heat_levels/nc_$number.png';

  /// Cria a partir do número (1-5)
  static HeatLevel fromNumber(int number) {
    switch (number) {
      case 1:
        return HeatLevel.nc1;
      case 2:
        return HeatLevel.nc2;
      case 3:
        return HeatLevel.nc3;
      case 4:
        return HeatLevel.nc4;
      case 5:
        return HeatLevel.nc5;
      default:
        return HeatLevel.nc1;
    }
  }
}

/// Estado operacional da cidade
class OperationalStatus {
  final CityStage cityStage;
  final HeatLevel heatLevel;
  final DateTime updatedAt;
  final bool isStale;

  const OperationalStatus({
    required this.cityStage,
    required this.heatLevel,
    required this.updatedAt,
    this.isStale = false,
  });

  factory OperationalStatus.fromJson(Map<String, dynamic> json) {
    return OperationalStatus(
      cityStage: CityStageExtension.fromNumber(json['city_stage'] ?? 1),
      heatLevel: HeatLevelExtension.fromNumber(json['heat_level'] ?? 1),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      isStale: json['is_stale'] ?? false,
    );
  }

  /// Retorna há quanto tempo foi atualizado em formato legível
  String get updatedAgo {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inSeconds < 60) {
      return 'Atualizado agora';
    } else if (diff.inMinutes < 60) {
      return 'Atualizado há ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'Atualizado há ${diff.inHours}h';
    } else {
      return 'Atualizado há ${diff.inDays}d';
    }
  }

  /// Status padrão (normal)
  static OperationalStatus get defaultStatus => OperationalStatus(
        cityStage: CityStage.stage1,
        heatLevel: HeatLevel.nc1,
        updatedAt: DateTime.now(),
      );
}
