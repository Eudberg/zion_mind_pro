import 'package:flutter/material.dart';
import '../models/tarefa_trilha.dart';
import '../models/sessao_estudo.dart';
import '../database/tarefas_trilha_dao.dart';
import '../database/sessoes_dao.dart';
import '../database/materias_dao.dart';
import '../database/assuntos_dao.dart';
import '../database/questoes_dao.dart';
import '../data/trilha_importer.dart';

class TrilhaController extends ChangeNotifier {
  final TarefasTrilhaDAO _tarefasDAO = TarefasTrilhaDAO();
  final SessoesDao _sessoesDAO = SessoesDao();

  List<TarefaTrilha> _tarefas = [];
  Map<String, int> _minutosPorDisciplinaSessoes = {};
  bool _isLoading = false;

  // CORREÇÃO: Campos marcados como final para satisfazer o linter,
  // já que não são reatribuídos diretamente (apenas seus conteúdos mudam).
  final DateTime _dataSelecionada = DateTime.now();
  final List<dynamic> _planoDoDia = [];

  // Getters principais
  List<TarefaTrilha> get tarefas => _tarefas;
  bool get isLoading => _isLoading;
  DateTime get dataSelecionada => _dataSelecionada;
  List<dynamic> get planoDoDia => _planoDoDia;

  // Getters para Métricas Globais
  int get totalMinutosPlanejados =>
      _tarefas.fold(0, (sum, t) => sum + t.chPlanejadaMin);
  int get totalMinutosEfetivos {
    final realizadoPorTarefa = <String, int>{};
    for (final t in _tarefas) {
      final d = _normDisciplina(t.disciplina);
      realizadoPorTarefa[d] = (realizadoPorTarefa[d] ?? 0) + (t.chEfetivaMin ?? 0);
    }

    final disciplinas = <String>{
      ...realizadoPorTarefa.keys,
      ..._minutosPorDisciplinaSessoes.keys,
    };

    int total = 0;
    for (final d in disciplinas) {
      final viaTarefa = realizadoPorTarefa[d] ?? 0;
      final viaSessao = _minutosPorDisciplinaSessoes[d] ?? 0;
      total += viaTarefa >= viaSessao ? viaTarefa : viaSessao;
    }
    return total;
  }

  int get diasAtivos {
    final datasUnicas = _tarefas
        .where((t) => t.dataConclusao != null)
        .map(
          (t) =>
              "${t.dataConclusao!.year}-${t.dataConclusao!.month}-${t.dataConclusao!.day}",
        )
        .toSet();
    return datasUnicas.length;
  }

  // --- LÓGICA DE MÉTRICAS POR MATÉRIA (Resolvendo erro na TelaEstatisticas) ---
  Map<String, Map<String, double>> get metricasPorMateria {
    Map<String, double> planejado = {};
    Map<String, double> realizado = {};
    Map<String, double> acertos = {};
    Map<String, double> totalQuestoes = {};

    for (var t in _tarefas) {
      planejado[t.disciplina] =
          (planejado[t.disciplina] ?? 0) + t.chPlanejadaMin;
      realizado[t.disciplina] =
          (realizado[t.disciplina] ?? 0) + (t.chEfetivaMin ?? 0);

      if (t.questoes != null && t.questoes! > 0) {
        totalQuestoes[t.disciplina] =
            (totalQuestoes[t.disciplina] ?? 0) + t.questoes!;
        acertos[t.disciplina] = (acertos[t.disciplina] ?? 0) + (t.acertos ?? 0);
      }
    }

    Map<String, Map<String, double>> resultados = {};
    planejado.forEach((disciplina, tempoTotal) {
      final d = _normDisciplina(disciplina);
      final realizadoViaTarefas = realizado[disciplina] ?? 0;
      final realizadoViaSessoes = _minutosPorDisciplinaSessoes[d] ?? 0;
      final realizadoFinal = realizadoViaTarefas >= realizadoViaSessoes
          ? realizadoViaTarefas
          : realizadoViaSessoes;
      double progresso = tempoTotal > 0
          ? realizadoFinal / tempoTotal
          : 0;
      double precisao = (totalQuestoes[disciplina] ?? 0) > 0
          ? (acertos[disciplina] ?? 0) / totalQuestoes[disciplina]!
          : 0;

      resultados[disciplina] = {
        'progresso': progresso,
        'precisao': precisao,
        'minutosRealizados': realizadoFinal.toDouble(),
        'minutosPlanejados': tempoTotal.toDouble(),
      };
    });
    return resultados;
  }

  // Mapeamento seguro de IDs para busca em listas
  Map<int, TarefaTrilha> get tarefasPorId => {
    for (var t in _tarefas)
      if (t.id != null) t.id!: t,
  };

  TrilhaController() {
    carregarTarefas();
  }

  /// REATIVIDADE: Método central de carregamento que aciona o notifyListeners()
  Future<void> carregarTarefas() async {
    _isLoading = true;
    notifyListeners();
    try {
      _tarefas = await _tarefasDAO.listarTodas();
      _tarefas.sort((a, b) => a.ordemGlobal.compareTo(b.ordemGlobal));
      final sessoes = await _sessoesDAO.listarTodas();
      final mapa = <String, int>{};
      for (final s in sessoes) {
        final d = _normDisciplina(s.disciplina);
        mapa[d] = (mapa[d] ?? 0) + s.duracaoMinutos;
      }
      _minutosPorDisciplinaSessoes = mapa;
    } catch (e) {
      debugPrint("Erro ao carregar tarefas: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  String _normDisciplina(String s) => s.trim().toUpperCase();
  String _norm(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  Future<Map<String, double>> desempenhoQuestoesPorMateria() async {
    final agregados = await QuestoesDao().agregadosPorMateria();
    final desempenho = <String, double>{};

    agregados.forEach((materia, valores) {
      final feitas = valores['feitas'] ?? 0;
      final acertos = valores['acertos'] ?? 0;
      final chave = _normDisciplina(materia);
      desempenho[chave] = feitas == 0 ? 0.0 : acertos / feitas;
    });

    return desempenho;
  }

  Future<Map<String, double>> desempenhoPorMateriaCanonica() async {
    final agg = await QuestoesDao().agregadosPorDisciplinaNormalizada();
    final materias = await MateriasDao().listarOrdenado();
    final out = <String, double>{};

    for (final m in materias) {
      final key = _norm(m.nome);
      final data = agg[key];
      final feitas = data?['feitas'] ?? 0;
      final acertos = data?['acertos'] ?? 0;
      out[m.nome] = feitas == 0 ? 0.0 : (acertos / feitas);
    }

    if (materias.isEmpty) {
      final disciplinas = _tarefas
          .map((t) => t.disciplina)
          .toSet()
          .toList()
        ..sort();
      for (final d in disciplinas) {
        final key = _norm(d);
        final data = agg[key];
        final feitas = data?['feitas'] ?? 0;
        final acertos = data?['acertos'] ?? 0;
        out[d] = feitas == 0 ? 0.0 : (acertos / feitas);
      }
    }

    return out;
  }

  Future<List<String>> listarMateriasParaMetricas() async {
    final materiasCatalogo = await MateriasDao().listarOrdenado();
    if (materiasCatalogo.isNotEmpty) {
      return materiasCatalogo.map((m) => m.nome).toList();
    }

    final nomes = <String>{};
    for (final t in _tarefas) {
      final nome = t.disciplina.trim();
      if (nome.isNotEmpty) nomes.add(nome);
    }
    final lista = nomes.toList();
    lista.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return lista;
  }

  Future<List<Map<String, dynamic>>> metricasUnificadas() async {
    final materias = await listarMateriasParaMetricas();
    final desempenhoPorMateria = await desempenhoPorMateriaCanonica();

    final lista = <Map<String, dynamic>>[];
    for (final materia in materias) {
      final chave = _normDisciplina(materia);

      int minutosPlanejados = 0;
      int minutosRealizados = 0;
      for (final t in _tarefas) {
        if (_normDisciplina(t.disciplina) == chave) {
          minutosPlanejados += t.chPlanejadaMin;
          minutosRealizados += t.chEfetivaMin ?? 0;
        }
      }

      lista.add({
        'materia': materia,
        'minutosPlanejados': minutosPlanejados,
        'minutosRealizados': minutosRealizados,
        'desempenho': desempenhoPorMateria[materia] ?? 0.0,
      });
    }

    return lista;
  }

  Future<void> syncCatalogoComTrilha() async {
    final materiasDao = MateriasDao();
    final assuntosDao = AssuntosDao();
    for (final t in _tarefas) {
      final materiaId = await materiasDao.upsertMateria(
        nome: t.disciplina,
        origem: 'trilha',
      );
      await assuntosDao.upsertAssunto(
        materiaId: materiaId,
        nome: t.assunto,
        origem: 'trilha',
      );
    }
  }

  /// LÓGICA DE AGRUPAMENTO (PDF): (ordem - 1) ~/ 25
  Map<int, List<TarefaTrilha>> get tarefasAgrupadasPorTrilha {
    Map<int, List<TarefaTrilha>> grupos = {};
    final pendentes = _tarefas.where((t) => !t.concluida).toList();

    for (var t in pendentes) {
      int trilhaNum = (t.ordemGlobal - 1) ~/ 25;
      if (!grupos.containsKey(trilhaNum)) grupos[trilhaNum] = [];
      grupos[trilhaNum]!.add(t);
    }
    return grupos;
  }

  /// REATIVIDADE: Agora chama carregarTarefas() para atualizar a UI instantaneamente
  Future<void> registrarConclusao(
    TarefaTrilha tarefa,
    int minutos,
    int questoes,
    int acertos,
  ) async {
    final now = DateTime.now();
    int novoEstagio = tarefa.estagioRevisao;
    DateTime? novaDataRevisao;

    if (tarefa.estagioRevisao == 0) {
      novoEstagio = 1;
      novaDataRevisao = now.add(const Duration(days: 7));
    } else if (tarefa.estagioRevisao == 1) {
      novoEstagio = 2;
      novaDataRevisao = now.add(const Duration(days: 30));
    } else if (tarefa.estagioRevisao == 2) {
      novoEstagio = 3;
      novaDataRevisao = now.add(const Duration(days: 60));
    } else if (tarefa.estagioRevisao == 3) {
      novoEstagio = 4;
      novaDataRevisao = null;
    }

    final tarefaAtualizada = TarefaTrilha(
      id: tarefa.id,
      ordemGlobal: tarefa.ordemGlobal,
      disciplina: tarefa.disciplina,
      assunto: tarefa.assunto,
      duracaoMinutos: tarefa.duracaoMinutos,
      chPlanejadaMin: tarefa.chPlanejadaMin,
      concluida: true,
      descricao: tarefa.descricao,
      fonteQuestoes: tarefa.fonteQuestoes,
      questoes: questoes > 0 ? questoes : (tarefa.questoes ?? 0),
      acertos: questoes > 0 ? acertos : (tarefa.acertos ?? 0),
      trilha: tarefa.trilha,
      tarefaCodigo: tarefa.tarefaCodigo,
      chEfetivaMin: (tarefa.chEfetivaMin ?? 0) + minutos,
      estagioRevisao: novoEstagio,
      dataConclusao: now,
      dataProximaRevisao: novaDataRevisao,
    );

    await _tarefasDAO.atualizar(tarefaAtualizada);

    final sessao = SessaoEstudo(
      tarefaId: tarefa.id ?? 0,
      disciplina: tarefa.disciplina,
      dataInicio: now,
      duracaoMinutos: minutos,
      questoesFeitas: questoes,
      questoesAcertadas: acertos,
    );
    await _sessoesDAO.inserir(sessao);

    await carregarTarefas();
  }

Future<void> registrarTempoCronometro({
    int? tarefaId,
    int? ordemGlobal,
    String? disciplina,
    String? assunto,
    required int minutos,
  }) async {
    if (minutos <= 0) return;

    TarefaTrilha? tarefa;

    if (tarefaId != null) {
      tarefa = await _tarefasDAO.buscarPorId(tarefaId);
    }

    if (tarefa == null &&
        ordemGlobal != null &&
        disciplina != null &&
        assunto != null) {
      tarefa = await _tarefasDAO.buscarPorChaveLogica(
        ordemGlobal: ordemGlobal,
        disciplina: disciplina,
        assunto: assunto,
      );
    }

    if (tarefa == null && tarefaId != null) {
      final indexMemoria = _tarefas.indexWhere((t) => t.id == tarefaId);
      if (indexMemoria >= 0) tarefa = _tarefas[indexMemoria];
    }

    if (tarefa == null && disciplina != null) {
      tarefa = await _tarefasDAO.buscarPrimeiraPorDisciplina(disciplina);
    }

    if (tarefa == null) {
      if (disciplina != null && disciplina.trim().isNotEmpty) {
        final sessaoSemTarefa = SessaoEstudo(
          tarefaId: 0,
          disciplina: disciplina,
          dataInicio: DateTime.now(),
          duracaoMinutos: minutos,
          questoesFeitas: 0,
          questoesAcertadas: 0,
        );
        await _sessoesDAO.inserir(sessaoSemTarefa);
        await carregarTarefas();
      }
      return;
    }

    final tarefaAtualizada = TarefaTrilha(
      id: tarefa.id,
      ordemGlobal: tarefa.ordemGlobal,
      disciplina: tarefa.disciplina,
      assunto: tarefa.assunto,
      duracaoMinutos: tarefa.duracaoMinutos,
      chPlanejadaMin: tarefa.chPlanejadaMin,
      concluida: tarefa.concluida,
      descricao: tarefa.descricao,
      fonteQuestoes: tarefa.fonteQuestoes,
      questoes: tarefa.questoes,
      acertos: tarefa.acertos,
      trilha: tarefa.trilha,
      tarefaCodigo: tarefa.tarefaCodigo,
      chEfetivaMin: (tarefa.chEfetivaMin ?? 0) + minutos,
      estagioRevisao: tarefa.estagioRevisao,
      dataConclusao: tarefa.dataConclusao,
      dataProximaRevisao: tarefa.dataProximaRevisao,
    );

    int linhasAfetadas = 0;
    if (tarefaAtualizada.id != null) {
      linhasAfetadas = await _tarefasDAO.atualizar(tarefaAtualizada);
    }
    if (linhasAfetadas == 0) {
      linhasAfetadas = await _tarefasDAO.atualizarPorChaveLogica(
        tarefaAtualizada,
      );
    }

    if (linhasAfetadas == 0 && disciplina != null) {
      final porDisciplina = await _tarefasDAO.buscarPrimeiraPorDisciplina(
        disciplina,
      );
      if (porDisciplina != null) {
        final fallback = TarefaTrilha(
          id: porDisciplina.id,
          ordemGlobal: porDisciplina.ordemGlobal,
          disciplina: porDisciplina.disciplina,
          assunto: porDisciplina.assunto,
          duracaoMinutos: porDisciplina.duracaoMinutos,
          chPlanejadaMin: porDisciplina.chPlanejadaMin,
          concluida: porDisciplina.concluida,
          descricao: porDisciplina.descricao,
          fonteQuestoes: porDisciplina.fonteQuestoes,
          questoes: porDisciplina.questoes,
          acertos: porDisciplina.acertos,
          trilha: porDisciplina.trilha,
          tarefaCodigo: porDisciplina.tarefaCodigo,
          chEfetivaMin: (porDisciplina.chEfetivaMin ?? 0) + minutos,
          estagioRevisao: porDisciplina.estagioRevisao,
          dataConclusao: porDisciplina.dataConclusao,
          dataProximaRevisao: porDisciplina.dataProximaRevisao,
        );
        if (fallback.id != null) {
          await _tarefasDAO.atualizar(fallback);
        }
      }
    }

    final sessao = SessaoEstudo(
      tarefaId: tarefa.id ?? 0,
      disciplina: tarefa.disciplina,
      dataInicio: DateTime.now(),
      duracaoMinutos: minutos,
      questoesFeitas: 0,
      questoesAcertadas: 0,
    );
    await _sessoesDAO.inserir(sessao);

    await carregarTarefas();
  }
Future<void> atualizarTarefaCampos(TarefaTrilha t) async {
    TarefaTrilha tarefaParaSalvar = t;

    // Busca estado anterior para detectar transição "não concluída -> concluída"
    final anterior = (t.id != null)
        ? await _tarefasDAO.buscarPorId(t.id!)
        : null;
    final concluiuAgora =
        (anterior?.concluida ?? false) == false && t.concluida;

    if (concluiuAgora) {
      final now = t.dataConclusao ?? DateTime.now();
      final estagioAtual = anterior?.estagioRevisao ?? t.estagioRevisao;

      int novoEstagio = estagioAtual;
      DateTime? novaDataRevisao;

      if (estagioAtual <= 0) {
        novoEstagio = 1;
        novaDataRevisao = now.add(const Duration(days: 7));
      } else if (estagioAtual == 1) {
        novoEstagio = 2;
        novaDataRevisao = now.add(const Duration(days: 30));
      } else if (estagioAtual == 2) {
        novoEstagio = 3;
        novaDataRevisao = now.add(const Duration(days: 60));
      } else if (estagioAtual == 3) {
        novoEstagio = 4;
        novaDataRevisao = null;
      }

      tarefaParaSalvar = TarefaTrilha(
        id: t.id,
        ordemGlobal: t.ordemGlobal,
        disciplina: t.disciplina,
        assunto: t.assunto,
        duracaoMinutos: t.duracaoMinutos,
        chPlanejadaMin: t.chPlanejadaMin,
        concluida: t.concluida,
        descricao: t.descricao,
        fonteQuestoes: t.fonteQuestoes,
        questoes: t.questoes,
        acertos: t.acertos,
        trilha: t.trilha,
        tarefaCodigo: t.tarefaCodigo,
        chEfetivaMin: t.chEfetivaMin,
        estagioRevisao: novoEstagio,
        dataConclusao: now,
        dataProximaRevisao: novaDataRevisao,
      );
    }

    await _tarefasDAO.atualizar(tarefaParaSalvar);
    await carregarTarefas();
  }

  void gerarPlanoDoDia() {
    notifyListeners();
  }

  void editarDataConclusao(int id, DateTime data) {
    notifyListeners();
  }

  List<TarefaTrilha> get tarefasPendentes {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tarefas.where((t) {
      if (t.estagioRevisao == 0 && !t.concluida) return true;
      if (t.dataProximaRevisao != null) {
        final revDate = t.dataProximaRevisao!;
        final revDateNormalized = DateTime(
          revDate.year,
          revDate.month,
          revDate.day,
        );
        return revDateNormalized.isBefore(today) ||
            revDateNormalized.isAtSameMomentAs(today);
      }
      return false;
    }).toList();
  }

  List<TarefaTrilha> get revisoesFuturas {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tarefas.where((t) {
      if (t.dataProximaRevisao == null) return false;
      final revDate = t.dataProximaRevisao!;
      final revDateNormalized = DateTime(
        revDate.year,
        revDate.month,
        revDate.day,
      );
      return revDateNormalized.isAfter(today);
    }).toList();
  }

Future<void> importarTrilha(List<int> bytes) async {
    _isLoading = true;
    notifyListeners();

    try {
      final importer = TrilhaImporter();
      final novasTarefas = await importer.importarBytes(bytes);

      // Carrega existentes para deduplicar por chave lógica
      final existentes = await _tarefasDAO.listarTodas();
      final chavesExistentes = existentes
          .map((t) => '${t.ordemGlobal}|${t.disciplina}|${t.assunto}')
          .toSet();

      for (final tarefa in novasTarefas) {
        final chave =
            '${tarefa.ordemGlobal}|${tarefa.disciplina}|${tarefa.assunto}';
        if (!chavesExistentes.contains(chave)) {
          await _tarefasDAO.inserir(tarefa);
          chavesExistentes.add(chave);
        }
      }

      await carregarTarefas();
      await syncCatalogoComTrilha();
    } catch (e) {
      debugPrint("Erro na importação: $e");
    }

    _isLoading = false;
    notifyListeners();
  }
}
