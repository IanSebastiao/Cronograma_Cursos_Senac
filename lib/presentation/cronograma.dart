// // ignore_for_file: avoid_print

// import 'dart:io';
// import 'package:excel/excel.dart';
// import '../data/repositories/calendarios_repository.dart';

// Future<void> gerarCronogramaExcel() async {
//   final repository = CalendariosRepository();
//   final calendarios = await repository.getCalendarios();

//   // Inicializa o Excel
//   var excel = Excel.createExcel();

//   // Seleciona ou cria a planilha
//   Sheet sheetObject = excel['Cronograma'];

//   // Adiciona o cabeçalho
//   sheetObject.appendRow(
//       ['ID', 'Ano', 'Mês', 'Data Início', 'Data Fim', 'ID da Turma']);

//   // Adiciona os dados
//   for (var calendario in calendarios) {
//     sheetObject.appendRow([
//       calendario.idCalendarios ?? '',
//       calendario.ano,
//       calendario.mes,
//       calendario.dataInicio,
//       calendario.dataFim,
//       calendario.idTurma
//     ]);
//   }

//   // Define o caminho onde o arquivo será salvo
//   final outputFile = File('cronograma.xlsx');

//   // Salva o arquivo Excel
//   final fileBytes = excel.encode();
//   if (fileBytes != null) {
//     await outputFile.writeAsBytes(fileBytes);
//     print('Arquivo Excel gerado com sucesso!');
//   } else {
//     print('Erro ao gerar o arquivo Excel.');
//   }
// }
