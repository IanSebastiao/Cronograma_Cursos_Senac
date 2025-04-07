// // ignore_for_file: library_private_types_in_public_api

// import 'package:cronograma/data/models/calendarios_model.dart';
// import 'package:cronograma/data/models/turma_model.dart';
// import 'package:cronograma/data/repositories/calendarios_repository.dart';
// import 'package:cronograma/data/repositories/turma_repository.dart';
// import 'package:cronograma/presentation/viewmodels/calendarios_viewmodels.dart';
// import 'package:cronograma/presentation/viewmodels/turma_viewmodels.dart';
// import 'package:flutter/material.dart';

// class CadastroCalendariosPage extends StatefulWidget {
//   const CadastroCalendariosPage({super.key});

//   @override
//   _CadastroCalendariosPageState createState() =>
//       _CadastroCalendariosPageState();
// }

// class _CadastroCalendariosPageState extends State<CadastroCalendariosPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _anoController = TextEditingController();
//   final _mesController = TextEditingController();
//   final _dataInicioController = TextEditingController();
//   final _dataFimController = TextEditingController();

//   final TurmaViewModel _turmaViewModel = TurmaViewModel(TurmaRepository());
//   final CalendariosViewModel _calendariosViewModel =
//       CalendariosViewModel(CalendariosRepository());

//   // Variáveis para data
//   DateTime? _dataInicio;
//   DateTime? _dataFim;

//   // Lista para armazenar os IDs das turmas
//   List<Turma> _turmas = [];
//   int? _selectedTurmaId;

//   // Método para carregar as turmas
//   Future<void> _loadTurmas() async {
//     try {
//       // Simulando uma chamada ao repositório para buscar as turmas
//       _turmas = await _turmaViewModel.getTurmas();
//       setState(() {
//         _turmas;
//       });
//     } catch (e) {
//       // ignore: use_build_context_synchronously
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Erro ao carregar turmas: $e')),
//       );
//     }
//   }

//   // Método para mostrar o DatePicker para a data de início
//   Future<void> _selectDataInicio(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _dataInicio ?? DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != _dataInicio) {
//       setState(() {
//         _dataInicio = picked;
//         _dataInicioController.text =
//             "${_dataInicio!.toLocal()}".split(' ')[0]; // formato "yyyy-mm-dd"
//       });
//     }
//   }

//   // Método para mostrar o DatePicker para a data de fim
//   Future<void> _selectDataFim(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _dataFim ?? DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != _dataFim) {
//       setState(() {
//         _dataFim = picked;
//         _dataFimController.text =
//             "${_dataFim!.toLocal()}".split(' ')[0]; // formato "yyyy-mm-dd"
//       });
//     }
//   }

//   // Método para salvar os dados
//   Future<void> _saveCalendario() async {
//     if (_formKey.currentState!.validate()) {
//       if (_dataInicio == null || _dataFim == null || _selectedTurmaId == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('Por favor, selecione as datas e a turma.')),
//         );
//         return;
//       }

//       // Convertendo as datas para string no formato correto
//       String dataInicioString =
//           _dataInicio!.toIso8601String().split('T')[0]; // formato "yyyy-MM-dd"
//       String dataFimString =
//           _dataFim!.toIso8601String().split('T')[0]; // formato "yyyy-MM-dd"

//       final calendario = Calendarios(
//         ano: int.parse(_anoController.text),
//         mes: _mesController.text, // Mes como String
//         dataInicio: dataInicioString,
//         dataFim: dataFimString,
//         idTurma: _selectedTurmaId!, // Aqui usamos o ID da turma selecionado
//       );

//       // Adicionando o calendário no repositório
//       await _calendariosViewModel.addCalendario(calendario);
//       // ignore: use_build_context_synchronously
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Calendário cadastrado com sucesso!')));
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _loadTurmas(); // Carregar as turmas quando a página for carregada
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Cadastro de Calendário')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               // Campo para o ano
//               TextFormField(
//                 controller: _anoController,
//                 decoration: const InputDecoration(labelText: 'Ano'),
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Por favor, insira o ano';
//                   }
//                   return null;
//                 },
//               ),
//               // Campo para o mês
//               TextFormField(
//                 controller: _mesController,
//                 decoration: const InputDecoration(labelText: 'Mês'),
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Por favor, insira o mês';
//                   }
//                   return null;
//                 },
//               ),
//               // Campo para o ID da turma com Dropdown
//               DropdownButtonFormField<int>(
//                 decoration: const InputDecoration(labelText: 'ID da Turma'),
//                 value: _selectedTurmaId,
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedTurmaId = value;
//                   });
//                 },
//                 items: _turmas.map((turma) {
//                   return DropdownMenuItem<int>(
//                     value: turma.idTurma,
//                     child: Text('Turma ${turma.turma}'),
//                   );
//                 }).toList(),
//                 validator: (value) {
//                   if (value == null) {
//                     return 'Por favor, selecione uma turma';
//                   }
//                   return null;
//                 },
//               ),
//               // Campo para a data de início
//               TextFormField(
//                 controller: _dataInicioController,
//                 decoration: const InputDecoration(labelText: 'Data Início'),
//                 readOnly: true,
//                 onTap: () => _selectDataInicio(context),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Por favor, selecione a data de início';
//                   }
//                   return null;
//                 },
//               ),
//               // Campo para a data de fim
//               TextFormField(
//                 controller: _dataFimController,
//                 decoration: const InputDecoration(labelText: 'Data Fim'),
//                 readOnly: true,
//                 onTap: () => _selectDataFim(context),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Por favor, selecione a data de fim';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _saveCalendario,
//                 child: const Text('Salvar Calendário'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
