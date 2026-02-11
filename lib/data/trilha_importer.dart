import 'dart:convert';
import 'package:csv/csv.dart';
import '../models/tarefa_trilha.dart';

class TrilhaImporter {
  Future<List<TarefaTrilha>> importarBytes(List<int> bytes) async {
    // 1. Decodifica
    String conteudo;
    try {
      conteudo = utf8.decode(bytes);
    } catch (e) {
      conteudo = latin1.decode(bytes);
    }

    // 2. Converte CSV
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
      if (col0.contains('TRILHA') && col2.contains('TAREFA')) continue;
      if (col3.contains('DISCIPLINA')) continue;
      if (col0.contains('AUDITOR')) continue;

      // Mapeamento
      String numTarefaRaw = linha[2].toString().trim();
      String disciplina = linha[3].toString().trim();
      String descricao = linha[7].toString().trim();

      if (disciplina.isEmpty && numTarefaRaw.isEmpty) continue;

      int? ordemReal = int.tryParse(numTarefaRaw);
      if (ordemReal == null) {
        ordemReal = contadorSequencial;
      } else {
        contadorSequencial = ordemReal + 1;
      }

      // CRIAÇÃO DO OBJETO (Usando os nomes da SUA classe)
      final tarefa = TarefaTrilha(
        id: null,

        // Mapeia 'ordem' para 'ordemGlobal'
        ordemGlobal: ordemReal,

        disciplina: disciplina.isEmpty ? 'Geral' : disciplina,

        // Mapeia 'assunto' para 'descricao'
        descricao: descricao,

        // Zera tudo conforme seu pedido
        concluida: false,
        questoes: 0,
        acertos: 0,

        // Campos extras nulos por enquanto
        trilha: 'Regular',
        tarefaCodigo: numTarefaRaw,
        chPlanejadaMin: 60, // Padrão 1h
        chEfetivaMin: 0,
      );

      tarefas.add(tarefa);
    }

    return tarefas;
  }
}
