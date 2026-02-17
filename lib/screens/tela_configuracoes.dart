import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/trilha_controller.dart';
import '../services/backup_service.dart';

class TelaConfiguracoes extends StatelessWidget {
  const TelaConfiguracoes({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configurações")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Dados e Importação",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: const Icon(Icons.file_upload, color: Colors.blue),
            title: const Text("Importar Trilha (CSV)"),
            subtitle: const Text(
              "Selecione o arquivo da sua trilha estratégica",
            ),
            onTap: () async {
              // Abre o seletor de arquivos
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['csv'],
                withData: true, // Necessário para ler os bytes
              );

              if (result != null && result.files.single.bytes != null) {
                // Chama o controller para processar os bytes
                await context.read<TrilhaController>().importarTrilha(
                  result.files.single.bytes!.toList(),
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Trilha importada com sucesso!"),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),
          const Text(
            "Sobre",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const ListTile(
            title: Text("Zion Mind Pro"),
            subtitle: Text("Versão 1.0.0 - Sistema de Revisão 7-30-60"),
          ),
          ListTile(
            tileColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Limpar todos os dados"),
            subtitle: const Text("Remove trilhas, sessões e histórico"),
            onTap: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Confirmação"),
                  content: const Text(
                    "Tem certeza que deseja apagar todos os dados?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Apagar"),
                    ),
                  ],
                ),
              );

              if (confirmar == true) {
                await context.read<TrilhaController>().resetarTudo();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Dados apagados com sucesso")),
                  );
                }
              }
            },
          ),
          ListTile(
            tileColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: const Icon(Icons.download, color: Colors.green),
            title: const Text("Exportar Backup"),
            subtitle: const Text(
              "Salva todas as tarefas e sessões em arquivo JSON",
            ),
            onTap: () async {
              final backupService = BackupService();
              final path = await backupService.exportarBackup();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Backup salvo em: $path")),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
