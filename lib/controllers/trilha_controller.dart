import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/trilha_importer.dart';
import '../database/tarefas_trilha_dao.dart';
import '../models/tarefa_trilha.dart';
import '../models/disciplina.dart';
import '../models/plano_item.dart'; // <--- Importando o SEU modelo existente

class TrilhaController extends ChangeNotifier {
  final TarefasTrilhaDao _dao = TarefasTrilhaDao();
  final TrilhaImporter _importer = TrilhaImporter();

  List<TarefaTrilha> _tarefas = [];
  List<TarefaTrilha> get tarefas => _tarefas;
  // --- FILTRO INTELIGENTE (O Segredo para esconder/mostrar) ---
  List<TarefaTrilha> get tarefasVisiveis {
    return _tarefas.where((t) {
      // 1. Se não está concluída, MOSTRA (é tarefa nova)
      if (!t.concluida) return true;

      // 2. Se está concluída, ESCONDE (por enquanto).
      // Futuramente, aqui colocaremos a lógica de revisão:
      // Ex: if (hoje >= dataRevisao) return true;

      return false;
    }).toList();
  }

  bool _carregando = false;
  bool get carregando => _carregando;

  // --- VARIÁVEIS DE PLANEJAMENTO ---
  DateTime _dataSelecionada = DateTime.now();

  // Agora a lista é de 'PlanoItem' para bater com a sua tela
  List<PlanoItem> _planoDoDia = [];

  // Mapa para a tela buscar o Nome/Descrição da tarefa pelo ID
  Map<int, TarefaTrilha> _tarefasPorId = {};

  // --- GETTERS (Resolvendo os erros da Tela) ---
  DateTime get dataSelecionada => _dataSelecionada;
  List<PlanoItem> get planoDoDia => _planoDoDia;
  Map<int, TarefaTrilha> get tarefasPorId => _tarefasPorId;

  // Estatísticas
  int get totalMinutosEfetivos =>
      _tarefas.where((t) => t.concluida).length * 60;
  int get totalMinutosPlanejados => _tarefas.length * 60;
  int get diasAtivos => 1;

  // ===========================================================================
  // LÓGICA DE PLANEJAMENTO (O Coração do problema)
  // ===========================================================================

  // Método que a tela chama (com ou sem data)
  void gerarPlanoDoDia([DateTime? data]) {
    _dataSelecionada = data ?? DateTime.now();

    if (_tarefas.isEmpty) {
      _planoDoDia = [];
      _tarefasPorId = {};
    } else {
      // 1. Filtra o que está pendente na trilha
      final pendentes = _tarefas.where((t) => !t.concluida).toList();

      // 2. Ordena pela ordem global da trilha
      pendentes.sort(
        (a, b) => (a.ordemGlobal ?? 0).compareTo(b.ordemGlobal ?? 0),
      );

      // 3. Define a META DO DIA (Ex: Próximas 6 tarefas)
      final metaDoDia = pendentes.take(6).toList();

      // 4. Converte Tarefas em PlanoItems (usando o SEU modelo existente)
      _planoDoDia = metaDoDia.map((t) {
        return PlanoItem(
          id: null, // Ainda não salvo no banco de planos, é em memória
          data: _dataSelecionada,
          tarefaId: t.id,
          tipo: 'estudo', // Define o tipo padrão
          minutosSugeridos: t.chPlanejadaMin ?? 60,
          status: 'pendente', // String, conforme seu modelo
        );
      }).toList();

      // 5. Popula o Mapa para a tela preencher os textos
      _tarefasPorId = {for (var t in _tarefas) t.id!: t};
    }

    notifyListeners();
  }

  // ===========================================================================
  // MÉTODOS DE MANUTENÇÃO (CARREGAR, IMPORTAR, ATUALIZAR)
  // ===========================================================================

  Future<void> carregarTarefas() async {
    _carregando = true;
    notifyListeners();

    try {
      _tarefas = await _dao.listarTodas();
      // Ao carregar o banco, já gera o plano para a tela não ficar vazia
      gerarPlanoDoDia(_dataSelecionada);
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> importarCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final tarefasImportadas = await _importer.importarBytes(bytes);

    if (tarefasImportadas.isEmpty) return;

    await _dao.limparTudo();
    await _dao.inserirEmLote(tarefasImportadas);

    await carregarTarefas();
  }

  Future<void> alternarConcluida(TarefaTrilha tarefa, bool concluida) async {
    final id = tarefa.id;
    if (id == null) return;
    await _dao.marcarConcluida(id, concluida);
    await carregarTarefas();
  }

// Substitua o método antigo por este novo dentro de TrilhaController
  Future<void> atualizarTarefaCampos({
    required int tarefaId,
    int? questoes,
    int? acertos,
    String? fonteQuestoes,
    bool? concluida,
    DateTime? dataConclusao, // <--- O parâmetro que faltava
  }) async {
    await _dao.atualizarCampos(
      tarefaId: tarefaId,
      questoes: questoes,
      acertos: acertos,
      fonteQuestoes: fonteQuestoes,
      concluida: concluida,
      dataConclusao: dataConclusao, // <--- Repassa para o banco
    );

    // Recarrega a lista para a tela atualizar
    await carregarTarefas();
  }  // ... dentro de TrilhaController ...

  // 1. PARA EDIÇÃO MANUAL DA DATA
  Future<void> editarDataConclusao(int tarefaId, DateTime novaData) async {
    await _dao.atualizarCampos(
      tarefaId: tarefaId,
      concluida: true, // Garante que fica concluída
      dataConclusao: novaData,
    );
    await carregarTarefas(); // Atualiza a tela
  }

  // 2. PARA O CRONÔMETRO CHAMAR
  Future<void> finalizarPeloCronometro(
    int tarefaId,
    int minutosEstudados,
  ) async {
    await _dao.atualizarCampos(
      tarefaId: tarefaId,
      concluida: true,
      dataConclusao: DateTime.now(), // Pega a hora exata que o timer parou
      minutosExecutados: minutosEstudados,
    );

    // Opcional: Se quiser vibrar ou tocar som aqui
    await carregarTarefas();
  }

  // --- PARA A TELA INICIAL (DISCIPLINAS) ---
  List<Disciplina> get disciplinasObjetos {
    final Map<String, List<TarefaTrilha>> agrupado = {};

    for (var t in _tarefas) {
      final nome = (t.disciplina ?? 'Geral').trim();
      if (!agrupado.containsKey(nome)) agrupado[nome] = [];
      agrupado[nome]!.add(t);
    }

    final lista = agrupado.entries.map((entry) {
      final total = entry.value.length;
      final concluidas = entry.value.where((t) => t.concluida).length;

      return Disciplina.fromTarefas(
        nome: entry.key,
        totalTarefas: total,
        tarefasConcluidas: concluidas,
      );
    }).toList();

    lista.sort((a, b) => a.nome.compareTo(b.nome));
    return lista;
  }
}
