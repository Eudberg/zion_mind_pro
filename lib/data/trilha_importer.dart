import 'dart:convert';
import 'package:csv/csv.dart';
import '../models/tarefa_trilha.dart';

class TrilhaImporter {
  Future<List<TarefaTrilha>> importarBytes(List<int> bytes) async {
    String conteudo;
    try {
      conteudo = utf8.decode(bytes);
    } catch (e) {
      conteudo = latin1.decode(bytes);
    }

    List<List<dynamic>> linhas = const CsvToListConverter(
      fieldDelimiter: ',',
      eol: '\n',
    ).convert(conteudo);

    List<TarefaTrilha> tarefas = [];
    int contadorSequencial = 1;

    for (var i = 0; i < linhas.length; i++) {
      final linha = linhas[i];
      if (linha.length < 8) continue;

      final col0 = linha[0].toString().toUpperCase();
      final col2 = linha[2].toString().toUpperCase();
      final col3 = linha[3].toString();

      // Pula cabeçalhos
      if (col0.contains('TRILHA') || col3.contains('DISCIPLINA')) continue;

      String numTarefaRaw = linha[2].toString().trim();
      String disciplina = linha[3].toString().trim();

      // CORREÇÃO: Mapeamento conforme o PDF
      // Assunto (o que aparece no card) costuma estar na coluna 4
      // Descrição completa (para o detalhe) na coluna 7
      String assuntoCsv = linha[4].toString().trim();
      String descricaoCsv = linha[7].toString().trim();

      if (disciplina.isEmpty && numTarefaRaw.isEmpty) continue;

      int? ordemReal = int.tryParse(numTarefaRaw);
      if (ordemReal == null) {
        ordemReal = contadorSequencial;
      } else {
        contadorSequencial = ordemReal + 1;
      }

      final tarefa = TarefaTrilha(
        id: null,
        ordemGlobal: ordemReal,
        disciplina: disciplina.isEmpty ? 'GERAL' : disciplina.toUpperCase(),
        assunto: assuntoCsv.isEmpty
            ? 'Sem Assunto'
            : assuntoCsv, // Texto do card
        descricao: descricaoCsv, // Texto completo ao clicar
        duracaoMinutos: 60,
        chPlanejadaMin: 60,
        concluida: false,
        trilha: 'REGULAR',
        tarefaCodigo: numTarefaRaw,
        chEfetivaMin: 0,
      );

      tarefas.add(tarefa);
    }

    return tarefas;
  }
}
