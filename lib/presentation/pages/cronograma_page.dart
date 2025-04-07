// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cronograma/core/database_helper.dart';

class CronogramaPage extends StatefulWidget {
  const CronogramaPage({super.key});

  @override
  _CronogramaPageState createState() => _CronogramaPageState();
}

class _CronogramaPageState extends State<CronogramaPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final Map<DateTime, List<Aula>> _events = {};
  final Map<DateTime, String> _feriados = {};
  bool _isLoading = true;
  final Map<int, int> _cargaHorariaUc = {}; // Mapa para armazenar carga horária por UC

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
    _carregarFeriadosBrasileiros(now.year);
    _carregarAulas();
    _carregarCargaHorariaUc();
  }

  Future<void> _carregarCargaHorariaUc() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final ucs = await db.query('Unidades_Curriculares');
      
      for (var uc in ucs) {
        _cargaHorariaUc[uc['idUc'] as int] = uc['carga_horaria'] as int;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar carga horária: $e')),
        );
      }
    }
  }

  void _carregarFeriadosBrasileiros(int ano) {
    _feriados[DateTime(ano, 1, 1)] = '🎉 Ano Novo';
    _feriados[DateTime(ano, 4, 21)] = '🎖 Tiradentes';
    _feriados[DateTime(ano, 5, 1)] = '👷 Dia do Trabalho';
    _feriados[DateTime(ano, 9, 7)] = '🇧🇷 Independência do Brasil';
    _feriados[DateTime(ano, 10, 12)] = '🙏 Nossa Senhora Aparecida';
    _feriados[DateTime(ano, 11, 2)] = '🕯 Finados';
    _feriados[DateTime(ano, 11, 15)] = '🏛 Proclamação da República';
    _feriados[DateTime(ano, 12, 25)] = '🎄 Natal';

    final pascoa = _calcularPascoa(ano);
    _feriados[pascoa] = '🐣 Páscoa';
    _feriados[pascoa.subtract(const Duration(days: 2))] = '✝ Sexta-Feira Santa';
    _feriados[pascoa.subtract(const Duration(days: 47))] = '🎭 Carnaval';
    _feriados[pascoa.add(const Duration(days: 60))] = '🍞 Corpus Christi';
  }

  DateTime _calcularPascoa(int ano) {
    final a = ano % 19;
    final b = ano ~/ 100;
    final c = ano % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final mes = (h + l - 7 * m + 114) ~/ 31;
    final dia = (h + l - 7 * m + 114) % 31 + 1;

    return DateTime(ano, mes, dia);
  }

  bool _isFeriado(DateTime day) {
    return _feriados.containsKey(DateTime(day.year, day.month, day.day));
  }

  bool _isDiaUtil(DateTime day) {
    // Verifica se não é fim de semana (sábado = 6, domingo = 7)
    if (day.weekday == 6 || day.weekday == 7) return false;
    
    // Verifica se não é feriado
    if (_isFeriado(day)) return false;
    
    return true;
  }

  Future<void> _carregarAulas() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final aulas = await db.query('Aulas');

      final Map<DateTime, List<Aula>> events = {};
      for (var aula in aulas) {
        final date = DateTime.parse(aula['data'] as String);
        final normalizedDate = DateTime(date.year, date.month, date.day);

        final aulaObj = Aula(
          idAula: aula['idAula'] as int,
          idUc: aula['idUc'] as int,
          idTurma: aula['idTurma'] as int,
          data: date,
          horario: aula['horario'] as String,
          status: aula['status'] as String,
        );

        events.putIfAbsent(normalizedDate, () => []).add(aulaObj);
      }

      setState(() {
        _events.clear();
        _events.addAll(events);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar aulas: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _adicionarAula() async {
    if (_selectedDay == null || !mounted) return;

    // Verificar se o dia selecionado é útil
    if (!_isDiaUtil(_selectedDay!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não é possível agendar aulas em finais de semana ou feriados')),
        );
      }
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      final turmas = await db.query('Turma');
      final ucs = await db.query('Unidades_Curriculares');

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Adicionar Nova Aula'),
          content: AdicionarAulaDialog(
            turmas: turmas, 
            ucs: ucs,
            cargaHorariaUc: _cargaHorariaUc,
            selectedDay: _selectedDay!,
            events: _events,
          ),
        ),
      );

      if (result != null && mounted) {
        // Atualizar carga horária restante
        final horasAula = result['horario'] == '19:00-22:00' ? 3 : 4;
        _cargaHorariaUc[result['idUc'] as int] = (_cargaHorariaUc[result['idUc'] as int] ?? 0) - horasAula;

        await db.insert('Aulas', {
          'idUc': result['idUc'],
          'idTurma': result['idTurma'],
          'data': DateFormat('yyyy-MM-dd').format(_selectedDay!),
          'horario': result['horario'],
          'status': 'Agendada',
        });
        await _carregarAulas();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar aula: $e')),
        );
      }
    }
  }

  Future<void> _removerAula(int idAula, int idUc, String horario) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('Aulas', where: 'idAula = ?', whereArgs: [idAula]);
      
      // Restaurar carga horária
      final horasAula = horario == '19:00-22:00' ? 3 : 4;
      _cargaHorariaUc[idUc] = (_cargaHorariaUc[idUc] ?? 0) + horasAula;
      
      if (mounted) await _carregarAulas();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover aula: $e')),
        );
      }
    }
  }

  List<Aula> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  String? _getFeriadoForDay(DateTime day) {
    return _feriados[DateTime(day.year, day.month, day.day)];
  }

  Widget _buildEventList() {
    if (_selectedDay == null) return const SizedBox();

    final events = _getEventsForDay(_selectedDay!);
    final feriado = _getFeriadoForDay(_selectedDay!);

    return Column(
      children: [
        if (feriado != null)
          Card(
            color: Colors.amber[100],
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.celebration, color: Colors.orange),
              title: Text(feriado),
            ),
          ),
        if (events.isEmpty && feriado == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nenhuma aula agendada'),
          ),
        ...events.map((aula) => _buildAulaCard(aula)),
      ],
    );
  }

  Widget _buildAulaCard(Aula aula) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 10,
          height: 40,
          color: _getColorByStatus(aula.status),
        ),
        title: FutureBuilder<Map<String, dynamic>>(
          future: _getAulaDetails(aula.idAula!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Carregando...');
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Text('Erro ao carregar dados');
            }
            final data = snapshot.data!;
            return Text('${data['nome_uc']} - ${data['turma']}');
          },
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _getAulaDetails(aula.idAula!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Carregando...');
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Erro ao carregar dados');
                }
                final data = snapshot.data!;
                return Text('Instrutor: ${data['nome_instrutor']}');
              },
            ),
            Text('Horário: ${aula.horario}'),
            Text('Status: ${aula.status}'),
            FutureBuilder<Map<String, dynamic>>(
              future: _getAulaDetails(aula.idAula!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Carregando...');
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Erro ao carregar dados');
                }
                final data = snapshot.data!;
                final cargaRestante = _cargaHorariaUc[aula.idUc] ?? 0;
                return Text('Carga horária restante: $cargaRestante horas');
              },
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removerAula(aula.idAula!, aula.idUc, aula.horario),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronograma de Aulas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Feriados'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: _feriados.entries
                        .map((e) => ListTile(
                              title: Text(e.value),
                              subtitle: Text(DateFormat('dd/MM/yyyy').format(e.key)),
                            ))
                        .toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarAula,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  locale: 'pt_BR',
                  headerStyle: HeaderStyle(
                    titleTextFormatter: (date, locale) =>
                        DateFormat('MMMM yyyy', 'pt_BR')
                            .format(date)
                            .toUpperCase(),
                    formatButtonVisible: false,
                    leftChevronIcon: const Icon(Icons.chevron_left),
                    rightChevronIcon: const Icon(Icons.chevron_right),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
                    weekendStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    weekendTextStyle: const TextStyle(color: Colors.red),
                    holidayTextStyle: TextStyle(color: Colors.red[800]),
                    markerDecoration: BoxDecoration(
                      color: Colors.blue[400],
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    outsideDaysVisible: false,
                  ),
                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, day) {
                      final text = DateFormat.EEEE('pt_BR').format(day);
                      return Center(
                        child: Text(text,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    },
                    defaultBuilder: (context, date, _) {
                      final isFeriado = _isFeriado(date);
                      final isDiaUtil = _isDiaUtil(date);
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isFeriado 
                              ? Colors.red[50] 
                              : !isDiaUtil 
                                  ? Colors.grey[200] 
                                  : null,
                          border: isFeriado 
                              ? Border.all(color: Colors.red) 
                              : !isDiaUtil 
                                  ? Border.all(color: Colors.grey) 
                                  : null,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isFeriado
                                  ? Colors.red[800]
                                  : date.weekday == 6 || date.weekday == 7
                                      ? Colors.red
                                      : null,
                              fontWeight: isFeriado ? FontWeight.bold : null,
                            ),
                          ),
                        ),
                      );
                    },
                    disabledBuilder: (context, date, _) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    if (_isDiaUtil(selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  onFormatChanged: (format) =>
                      setState(() => _calendarFormat = format),
                  onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                  eventLoader: _getEventsForDay,
                  enabledDayPredicate: (day) => _isDiaUtil(day),
                ),
                Expanded(child: _buildEventList()),
              ],
            ),
    );
  }

  Color _getColorByStatus(String status) {
    switch (status) {
      case 'Realizada':
        return Colors.green;
      case 'Cancelada':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Future<Map<String, dynamic>> _getAulaDetails(int idAula) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('''
      SELECT Aulas.*, Unidades_Curriculares.nome_uc, Turma.turma, Instrutores.nome_instrutor
      FROM Aulas
      JOIN Unidades_Curriculares ON Aulas.idUc = Unidades_Curriculares.idUc
      JOIN Turma ON Aulas.idTurma = Turma.idTurma
      JOIN Instrutores ON Turma.idInstrutor = Instrutores.idInstrutor
      WHERE Aulas.idAula = ?
    ''', [idAula]);

      if (result.isEmpty) {
        return {
          'nome_uc': 'Não encontrado',
          'turma': 'Não encontrada',
          'nome_instrutor': 'Não encontrado'
        };
      }

      return result.first;
    } catch (e) {
      return {
        'nome_uc': 'Erro: $e',
        'turma': 'Erro: $e',
        'nome_instrutor': 'Erro: $e'
      };
    }
  }
}

class AdicionarAulaDialog extends StatefulWidget {
  final List<Map<String, dynamic>> turmas;
  final List<Map<String, dynamic>> ucs;
  final Map<int, int> cargaHorariaUc;
  final DateTime selectedDay;
  final Map<DateTime, List<Aula>> events;

  const AdicionarAulaDialog({
    super.key,
    required this.turmas,
    required this.ucs,
    required this.cargaHorariaUc,
    required this.selectedDay,
    required this.events,
  });

  @override
  _AdicionarAulaDialogState createState() => _AdicionarAulaDialogState();
}

class _AdicionarAulaDialogState extends State<AdicionarAulaDialog> {
  int? _selectedTurmaId;
  int? _selectedUcId;
  String _horario = '08:00-10:00';
  int _cargaRestante = 0;
  List<Map<String, dynamic>> _ucsFiltradas = [];

  @override
  void initState() {
    super.initState();
    _ucsFiltradas = widget.ucs;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            value: _selectedTurmaId,
            decoration: const InputDecoration(labelText: 'Turma'),
            items: widget.turmas
                .map((turma) => DropdownMenuItem(
                      value: turma['idTurma'] as int,
                      child: Text(turma['turma'] as String),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedTurmaId = value;
                _selectedUcId = null;
                _ucsFiltradas = widget.ucs;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _selectedUcId,
            decoration: const InputDecoration(labelText: 'Unidade Curricular'),
            items: _ucsFiltradas.map((uc) {
              final cargaHoraria = widget.cargaHorariaUc[uc['idUc'] as int] ?? 0;
              final horasPorAula = _horario == '19:00-22:00' ? 3 : 4;
              final podeAgendar = cargaHoraria >= horasPorAula;
              
              // Verificar se já existe aula para esta UC no dia selecionado
              final jaAgendadaNoDia = widget.events[DateTime(widget.selectedDay.year, widget.selectedDay.month, widget.selectedDay.day)]?.any((aula) => aula.idUc == uc['idUc']) ?? false;

              return DropdownMenuItem(
                value: uc['idUc'] as int,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(uc['nome_uc'] as String),
                    Text(
                      'Carga restante: $cargaHoraria horas',
                      style: TextStyle(
                        fontSize: 12,
                        color: cargaHoraria < horasPorAula ? Colors.red : Colors.grey,
                      ),
                    ),
                    if (jaAgendadaNoDia)
                      const Text(
                        'Já possui aula neste dia',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
                enabled: podeAgendar && !jaAgendadaNoDia,
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedUcId = value;
                if (value != null) {
                  _cargaRestante = widget.cargaHorariaUc[value] ?? 0;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _horario,
            decoration: const InputDecoration(labelText: 'Horário'),
            items: [
              '08:00-10:00',
              '10:00-12:00',
              '14:00-16:00',
              '16:00-18:00',
              '19:00-22:00'
            ].map((e) {
              final horasPorAula = e == '19:00-22:00' ? 3 : 4;
              final podeAgendar = _selectedUcId == null ? true : (widget.cargaHorariaUc[_selectedUcId] ?? 0) >= horasPorAula;
              
              return DropdownMenuItem(
                value: e,
                child: Text(e),
                enabled: podeAgendar,
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _horario = value!;
              });
            },
          ),
          if (_selectedUcId != null) ...[
            const SizedBox(height: 16),
            Text(
              'Carga horária restante: ${widget.cargaHorariaUc[_selectedUcId] ?? 0} horas',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _podeSalvar() ? () {
                  final horasPorAula = _horario == '19:00-22:00' ? 3 : 4;
                  if (_selectedUcId != null && (widget.cargaHorariaUc[_selectedUcId] ?? 0) >= horasPorAula) {
                    Navigator.pop(context, {
                      'idTurma': _selectedTurmaId,
                      'idUc': _selectedUcId,
                      'horario': _horario,
                    });
                  }
                } : null,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _podeSalvar() {
    if (_selectedTurmaId == null || _selectedUcId == null) return false;
    
    final horasPorAula = _horario == '19:00-22:00' ? 3 : 4;
    final cargaDisponivel = widget.cargaHorariaUc[_selectedUcId] ?? 0;
    
    // Verificar se já existe aula para esta UC no dia selecionado
    final jaAgendadaNoDia = widget.events[DateTime(widget.selectedDay.year, widget.selectedDay.month, widget.selectedDay.day)]?.any((aula) => aula.idUc == _selectedUcId) ?? false;
    
    return cargaDisponivel >= horasPorAula && !jaAgendadaNoDia;
  }
}

class Aula {
  final int? idAula;
  final int idUc;
  final int idTurma;
  final DateTime data;
  final String horario;
  final String status;

  Aula({
    this.idAula,
    required this.idUc,
    required this.idTurma,
    required this.data,
    required this.horario,
    this.status = 'Agendada',
  });
}