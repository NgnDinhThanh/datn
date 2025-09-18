import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/exam_provider.dart';
import '../../models/exam_model.dart';
import '../../providers/class_provider.dart';
import '../../providers/answer_sheet_provider.dart';
import '../../providers/answer_key_provider.dart';
import 'package:go_router/go_router.dart';

class QuizDetailScreen extends StatefulWidget {
  final String quizId;
  const QuizDetailScreen({required this.quizId, Key? key}) : super(key: key);

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  int? _selectedVersionIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadAnswerKeys();
      _reloadAnswerSheets();
    });
  }

  Future<void> _reloadAnswerKeys() async {
    final answerKeyProvider = Provider.of<AnswerKeyProvider>(context, listen: false);
    await answerKeyProvider.fetchAnswerKeys(context, widget.quizId);
    setState(() {});
  }

  Future<void> _reloadAnswerSheets() async {
    final answerSheetProvider = Provider.of<AnswerSheetProvider>(context, listen: false);
    await answerSheetProvider.fetchAnswerSheets(context);
  }

  @override
  Widget build(BuildContext context) {
    final examProvider = Provider.of<ExamProvider>(context);
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    final answerSheetProvider = Provider.of<AnswerSheetProvider>(context, listen: true);
    final answerKeyProvider = Provider.of<AnswerKeyProvider>(context, listen: true);

    final quizList = examProvider.exams.where((e) => e.id == widget.quizId);
    final ExamModel? quiz = quizList.isNotEmpty ? quizList.first : null;
    if (quiz == null) {
      return Scaffold(
        body: const Center(child: Text('Quiz not found')),
      );
    }

    // DEBUG LOG: In ra id answer sheet và danh sách answer sheet
    // ignore: avoid_print
    print('quiz.answersheet: ${quiz.answersheet}');
    for (var a in answerSheetProvider.answerSheets) {
      // ignore: avoid_print
      print('answerSheet.id: ${a.id}, name: ${a.name}');
    }

    // Lấy tên lớp và answer sheet
    final classNames = quiz.class_codes
        .map((code) {
      final classObj = classProvider.classes.where((c) => c.class_code == code);
      return classObj.isNotEmpty ? classObj.first.class_name : code;
    })
        .join(', ');
    String answerSheetName = 'Unknown';
    String debugAnswerSheetIds = '';
    if (answerSheetProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (answerSheetProvider.answerSheets.isEmpty) {
      answerSheetName = 'No answer sheets loaded';
    } else {
      final answerSheetObj = answerSheetProvider.answerSheets.where((a) => a.id == quiz.answersheet);
      debugAnswerSheetIds = answerSheetProvider.answerSheets.map((a) => a.id).join(', ');
      answerSheetName = answerSheetObj.isNotEmpty ? answerSheetObj.first.name : 'Unknown';
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header lớn giống ZipGrade
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Quiz: ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                            Text(quiz.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('Class: ', style: TextStyle(fontSize: 20, color: Colors.grey[700])),
                            Text(classNames, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Row các block chính
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Block Quiz Details (thu nhỏ)
                  Flexible(
                    flex: 2,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row tiêu đề và icon edit
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('QUIZ DETAILS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                                                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.teal),
                                  tooltip: 'Edit Quiz',
                                  onPressed: () {
                                    context.go('/quizzes/${quiz.id}/edit');
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Table(
                              columnWidths: const {
                                0: IntrinsicColumnWidth(),
                                1: FlexColumnWidth(),
                              },
                              children: [
                                TableRow(children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: Text('Name:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Text(quiz.name),
                                  ),
                                ]),
                                TableRow(children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: Text('Answer Sheet:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(answerSheetName),
                                        if (answerSheetName == 'Unknown' && debugAnswerSheetIds.isNotEmpty)
                                          Text('Debug ids: ' + debugAnswerSheetIds, style: const TextStyle(fontSize: 10, color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ]),
                                TableRow(children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Text(quiz.date),
                                  ),
                                ]),
                                TableRow(children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: Text('Class:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Text(classNames),
                                  ),
                                ]),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Block Score Distribution (placeholder)
                  Flexible(
                    flex: 3,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('SCORE DISTRIBUTION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                                const SizedBox(width: 8),
                                Icon(Icons.bar_chart, color: Colors.teal, size: 18),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 180,
                              alignment: Alignment.center,
                              child: const Text('JS chart by amCharts (placeholder)', style: TextStyle(color: Colors.grey)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Row các block phụ
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Block Answer Key
                  Flexible(
                    flex: 2,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('ANSWER KEY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                                const SizedBox(width: 8),
                                Icon(Icons.key, color: Colors.teal, size: 18),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (answerKeyProvider.isLoading)
                              const CircularProgressIndicator(),
                            if (answerKeyProvider.error != null)
                              Text('Error: ${answerKeyProvider.error}', style: const TextStyle(color: Colors.red)),
                            if (!answerKeyProvider.isLoading && answerKeyProvider.error == null)
                              ...[
                                if (answerKeyProvider.answerKeys.isEmpty)
                                  const Text('No answer keys found.'),
                                if (answerKeyProvider.answerKeys.isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Number of Versions: ${answerKeyProvider.answerKeys.first.numVersions}'),
                                      const SizedBox(height: 8),
                                      Text('Version Codes:'),
                                      Wrap(
                                        spacing: 8,
                                        children: List.generate(
                                          answerKeyProvider.answerKeys.first.versions.length,
                                          (i) {
                                            final v = answerKeyProvider.answerKeys.first.versions[i];
                                            return GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    final questions = v['questions'] as List;
                                                    return AlertDialog(
                                                      title: Text('Answers for Version: ${v['version_code']}'),
                                                      content: SizedBox(
                                                        width: 300,
                                                        child: ListView.builder(
                                                          shrinkWrap: true,
                                                          itemCount: questions.length,
                                                          itemBuilder: (context, j) {
                                                            final q = questions[j];
                                                            return ListTile(
                                                              dense: true,
                                                              title: Text('Q${q['order']}: ${q['answer']}'),
                                                              subtitle: Text('Question code: ${q['question_code']}'),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.of(context).pop(),
                                                          child: const Text('Close'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              child: Chip(
                                                label: Text(v['version_code']?.toString() ?? ''),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                context.go('/quizzes/${quiz.id}/edit-answer-keys');
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit Answer Keys'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Block Graded Papers (placeholder)
                  Flexible(
                    flex: 3,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('GRADED PAPERS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                                const SizedBox(width: 8),
                                Icon(Icons.assignment_turned_in, color: Colors.teal, size: 18),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 80,
                              alignment: Alignment.center,
                              child: const Text('No data available in table', style: TextStyle(color: Colors.grey)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Block Quiz Statistics (giữ nguyên)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('QUIZ STATISTICS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                          const SizedBox(width: 8),
                          Icon(Icons.analytics, color: Colors.teal, size: 18),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.picture_as_pdf, size: 18),
                            label: const Text('PDF'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[200]),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.table_chart, size: 18),
                            label: const Text('CSV'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[200]),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.grid_on, size: 18),
                            label: const Text('Excel'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[200]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Table(
                        columnWidths: const {
                          0: IntrinsicColumnWidth(),
                          1: FlexColumnWidth(),
                        },
                        children: const [
                          TableRow(children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('Number of Papers:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('0'),
                            ),
                          ]),
                          TableRow(children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('Number of Questions:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('0'),
                            ),
                          ]),
                          TableRow(children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('Possible Points:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('0'),
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Table(
                        columnWidths: const {
                          0: IntrinsicColumnWidth(),
                          1: FlexColumnWidth(),
                          2: IntrinsicColumnWidth(),
                          3: FlexColumnWidth(),
                        },
                        children: const [
                          TableRow(children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('Minimum', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('0'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('Maximum', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('0'),
                            ),
                          ]),
                          TableRow(children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('Average', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('0'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('Median', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('0'),
                            ),
                          ]),
                          TableRow(children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('Std. Dev.', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('0.00'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text('', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text(''),
                            ),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Block Item Analysis (giữ nguyên)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('ITEM ANALYSIS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                      SizedBox(height: 12),
                      Text('No data available in table', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}