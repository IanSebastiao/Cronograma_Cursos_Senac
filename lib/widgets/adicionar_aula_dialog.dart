// // ignore_for_file: library_private_types_in_public_api

// import 'package:flutter/material.dart';

// class AdicionarAulaDialog extends StatefulWidget {
//   final List<Map<String, dynamic>> turmas;
//   final List<Map<String, dynamic>> ucs;

//   const AdicionarAulaDialog({super.key, required this.turmas, required this.ucs});

//   @override
//   _AdicionarAulaDialogState createState() => _AdicionarAulaDialogState();
// }

// class _AdicionarAulaDialogState extends State<AdicionarAulaDialog> {
//   int? _turmaSelecionada;
//   int? _ucSelecionada;
//   String _horario = '';

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Adicionar Aula'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           DropdownButtonFormField<int>(
//             decoration: const InputDecoration(labelText: 'Turma'),
//             items: widget.turmas.map((turma) {
//               return DropdownMenuItem<int>(
//                 value: turma['idTurma'],
//                 child: Text(turma['nome']),
//               );
//             }).toList(),
//             onChanged: (value) => setState(() => _turmaSelecionada = value),
//           ),
//           DropdownButtonFormField<int>(
//             decoration: const InputDecoration(labelText: 'Unidade Curricular'),
//             items: widget.ucs.map((uc) {
//               return DropdownMenuItem<int>(
//                 value: uc['idUc'],
//                 child: Text(uc['nome']),
//               );
//             }).toList(),
//             onChanged: (value) => setState(() => _ucSelecionada = value),
//           ),
//           TextField(
//             decoration: const InputDecoration(labelText: 'Horário'),
//             onChanged: (value) => setState(() => _horario = value),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Cancelar'),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             if (_turmaSelecionada != null && _ucSelecionada != null && _horario.isNotEmpty) {
//               Navigator.pop(context, {
//                 'idTurma': _turmaSelecionada,
//                 'idUc': _ucSelecionada,
//                 'horario': _horario,
//               });
//             }
//           },
//           child: const Text('Adicionar'),
//         ),
//       ],
//     );
//   }
// }
