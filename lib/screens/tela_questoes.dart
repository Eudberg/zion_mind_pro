import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../database/questoes_dao.dart';
import '../database/materias_dao.dart';
import '../database/assuntos_dao.dart';
import '../models/questao.dart';
import '../models/materia.dart';
import '../models/assunto.dart';

class TelaQuestoes extends StatefulWidget {
  const TelaQuestoes({super.key});

  @override
  State<TelaQuestoes> createState() => _TelaQuestoesState();
}

class _TelaQuestoesState extends State<TelaQuestoes> {
  final QuestoesDao _questoesDao = QuestoesDao();
  final MateriasDao _materiasDao = MateriasDao();
  final AssuntosDao _assuntosDao = AssuntosDao();

  final _materiaTextCtrl = TextEditingController();
  final _assuntoTextCtrl = TextEditingController();
  final _feitasController = TextEditingController();
  final _acertosController = TextEditingController();

  List<Materia> _materiasCatalogo = [];
  List<Assunto> _assuntosCatalogo = [];
  Materia? _materiaSelecionada;
  int? _materiaIdSelecionada;

  @override
  void dispose() {
    _materiaTextCtrl.dispose();
    _assuntoTextCtrl.dispose();
    _feitasController.dispose();
    _acertosController.dispose();
    super.dispose();
  }

  Future<void> _carregarMateriasCatalogo() async {
    _materiasCatalogo = await _materiasDao.listarOrdenado();
  }

  Future<void> _carregarAssuntosPorMateria(String materiaNome) async {
    final materia = materiaNome.trim();
    if (materia.isEmpty) {
      _materiaIdSelecionada = null;
      _materiaSelecionada = null;
      _assuntosCatalogo = [];
      return;
    }

    final materiaId = await _materiasDao.upsertMateria(
      nome: materia,
      origem: 'manual',
    );
    _materiaIdSelecionada = materiaId;
    _materiaSelecionada = _materiasCatalogo.where((m) => m.id == materiaId).isNotEmpty
        ? _materiasCatalogo.firstWhere((m) => m.id == materiaId)
        : null;
    _assuntosCatalogo = await _assuntosDao.listarPorMateria(materiaId);
  }

  void _limparFormularioModal() {
    _materiaTextCtrl.clear();
    _assuntoTextCtrl.clear();
    _feitasController.clear();
    _acertosController.clear();
    _materiaSelecionada = null;
    _materiaIdSelecionada = null;
    _assuntosCatalogo = [];
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _adicionarQuestao() async {
    await _carregarMateriasCatalogo();
    if (!mounted) return;

    _limparFormularioModal();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final materiaPreenchida = _materiaTextCtrl.text.trim().isNotEmpty;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Registrar Batalha',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 15),
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _materiaTextCtrl.text),
                  optionsBuilder: (textEditingValue) {
                    final q = textEditingValue.text.trim().toLowerCase();
                    if (q.isEmpty) {
                      return _materiasCatalogo.map((m) => m.nome);
                    }
                    return _materiasCatalogo
                        .map((m) => m.nome)
                        .where((nome) => nome.toLowerCase().contains(q));
                  },
                  onSelected: (selecionada) async {
                    _materiaTextCtrl.text = selecionada;
                    _assuntoTextCtrl.clear();
                    await _carregarAssuntosPorMateria(selecionada);
                    if (!mounted) return;
                    setModalState(() {});
                  },
                  fieldViewBuilder:
                      (context, textCtrl, focusNode, onFieldSubmitted) {
                    if (textCtrl.text != _materiaTextCtrl.text) {
                      textCtrl.text = _materiaTextCtrl.text;
                      textCtrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: textCtrl.text.length),
                      );
                    }

                    return TextField(
                      controller: textCtrl,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Materia',
                      ),
                      onChanged: (value) {
                        _materiaTextCtrl.text = value;
                        _materiaSelecionada = null;
                        _materiaIdSelecionada = null;
                        _assuntoTextCtrl.clear();
                        _assuntosCatalogo = [];
                        setModalState(() {});
                      },
                      onEditingComplete: () async {
                        _materiaTextCtrl.text = textCtrl.text;
                        await _carregarAssuntosPorMateria(textCtrl.text);
                        if (!mounted) return;
                        setModalState(() {});
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _assuntoTextCtrl.text),
                  optionsBuilder: (textEditingValue) {
                    if (!materiaPreenchida) {
                      return const Iterable<String>.empty();
                    }
                    final q = textEditingValue.text.trim().toLowerCase();
                    if (q.isEmpty) {
                      return _assuntosCatalogo.map((a) => a.nome);
                    }
                    return _assuntosCatalogo
                        .map((a) => a.nome)
                        .where((nome) => nome.toLowerCase().contains(q));
                  },
                  onSelected: (selecionado) {
                    _assuntoTextCtrl.text = selecionado;
                    setModalState(() {});
                  },
                  fieldViewBuilder:
                      (context, textCtrl, focusNode, onFieldSubmitted) {
                    if (textCtrl.text != _assuntoTextCtrl.text) {
                      textCtrl.text = _assuntoTextCtrl.text;
                      textCtrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: textCtrl.text.length),
                      );
                    }

                    return TextField(
                      controller: textCtrl,
                      focusNode: focusNode,
                      enabled: materiaPreenchida,
                      decoration: const InputDecoration(
                        labelText: 'Assunto',
                      ),
                      onTap: () async {
                        if (_materiaIdSelecionada == null &&
                            _materiaTextCtrl.text.trim().isNotEmpty) {
                          await _carregarAssuntosPorMateria(
                            _materiaTextCtrl.text,
                          );
                          if (!mounted) return;
                          setModalState(() {});
                        }
                      },
                      onChanged: (value) {
                        _assuntoTextCtrl.text = value;
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _feitasController,
                        decoration: const InputDecoration(labelText: 'Qtd Feitas'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextField(
                        controller: _acertosController,
                        decoration: const InputDecoration(labelText: 'Qtd Acertos'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final materia = _materiaTextCtrl.text.trim();
                    final assunto = _assuntoTextCtrl.text.trim();
                    final feitasStr = _feitasController.text.trim();
                    final acertosStr = _acertosController.text.trim();

                    if (materia.isEmpty || assunto.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preencha matéria e assunto')),
                      );
                      return;
                    }
                    if (feitasStr.isEmpty || acertosStr.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preencha feitas e acertos')),
                      );
                      return;
                    }

                    final feitas = int.tryParse(feitasStr) ?? -1;
                    final acertos = int.tryParse(acertosStr) ?? -1;
                    if (feitas < 0 || acertos < 0 || acertos > feitas) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Valores inválidos')),
                      );
                      return;
                    }

                    try {
                      debugPrint(
                        '[QUESTOES] salvando: materia=$materia assunto=$assunto feitas=$feitas acertos=$acertos',
                      );

                      final materiaId = await _materiasDao.upsertMateria(
                        nome: materia,
                        origem: 'manual',
                      );
                      await _assuntosDao.upsertAssunto(
                        materiaId: materiaId,
                        nome: assunto,
                        origem: 'manual',
                      );

                      await QuestoesDao().inserir(
                        Questao(
                          materia: materia,
                          assunto: assunto,
                          qtdFeitas: feitas,
                          qtdAcertos: acertos,
                          data: DateTime.now(),
                        ),
                      );

                      debugPrint('[QUESTOES] inseriu no DB com sucesso');
                    } catch (e, st) {
                      debugPrint('[QUESTOES] ERRO ao salvar: $e');
                      debugPrint('$st');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao salvar: $e')),
                      );
                      return;
                    }

                    _limparFormularioModal();
                    Navigator.of(ctx).pop();
                    if (!mounted) return;
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Salvar Desempenho'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool> _salvarNoBanco() async {
    final materia = _materiaTextCtrl.text.trim();
    final assunto = _assuntoTextCtrl.text.trim();
    final feitas = int.tryParse(_feitasController.text) ?? -1;
    final acertos = int.tryParse(_acertosController.text) ?? -1;

    if (materia.isEmpty) {
      _mostrarErro('Informe uma materia.');
      return false;
    }
    if (assunto.isEmpty) {
      _mostrarErro('Informe um assunto.');
      return false;
    }
    if (feitas < 0) {
      _mostrarErro('Qtd feitas deve ser >= 0.');
      return false;
    }
    if (acertos < 0) {
      _mostrarErro('Qtd acertos deve ser >= 0.');
      return false;
    }
    if (acertos > feitas) {
      _mostrarErro('Qtd acertos nao pode ser maior que qtd feitas.');
      return false;
    }

    final materiaId = await _materiasDao.upsertMateria(
      nome: materia,
      origem: 'manual',
    );
    await _assuntosDao.upsertAssunto(
      materiaId: materiaId,
      nome: assunto,
      origem: 'manual',
    );

    final novaQuestao = Questao(
      materia: materia,
      assunto: assunto,
      data: DateTime.now(),
      qtdFeitas: feitas,
      qtdAcertos: acertos,
    );
    await _questoesDao.inserir(novaQuestao);

    await _carregarMateriasCatalogo();
    await _carregarAssuntosPorMateria(materia);

    _limparFormularioModal();
    return true;
  }

  Color _getCorDesempenho(BuildContext context, double porcentagem) {
    if (porcentagem >= 80) return Theme.of(context).colorScheme.secondary;
    if (porcentagem >= 60) return const Color(0xFFF59E0B);
    return Theme.of(context).colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Questões'),
      ),
      body: FutureBuilder<List<Questao>>(
        future: _questoesDao.listarTodas(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final lista = snapshot.data!;

          if (lista.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma questão registrada.\nVamos treinar?',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lista.length,
            itemBuilder: (ctx, i) {
              final q = lista[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            q.materia,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${q.desempenho.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getCorDesempenho(context, q.desempenho),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        q.assunto,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 10),
                      LinearPercentIndicator(
                        lineHeight: 8.0,
                        percent: q.desempenho / 100,
                        progressColor: _getCorDesempenho(context, q.desempenho),
                        backgroundColor: Theme.of(context).cardColor,
                        barRadius: const Radius.circular(4),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${q.qtdAcertos} acertos de ${q.qtdFeitas} questões',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarQuestao,
        child: const Icon(Icons.quiz),
      ),
    );
  }
}
