import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../models/exam_model.dart';
import '../providers/class_provider.dart';
import '../providers/answer_sheet_provider.dart';

class QuizDetailScreen extends StatelessWidget {
  final ExamModel quiz;
  const QuizDetailScreen({Key? key, required this.quiz}) : super(key: key);

  void _printAnswerSheet(BuildContext context, String filePdf) async {
    if (filePdf.isEmpty) return;
    final uri = Uri.parse(filePdf);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open PDF file.')),
      );
    }
  }

  void _showPrintOptions(BuildContext context, String filePdf) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Chia sẻ link PDF'),
                onTap: () {
                  Share.share(filePdf);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy link'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: filePdf));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã copy link PDF!')));
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final classProvider = Provider.of<ClassProvider>(context);
    final answerSheetProvider = Provider.of<AnswerSheetProvider>(context);

    // Nếu danh sách class hoặc answer sheet rỗng, tự động fetch
    if (classProvider.classes.isEmpty) {
      Future.microtask(() => Provider.of<ClassProvider>(context, listen: false).fetchClasses(context));
    }
    if (answerSheetProvider.answerSheets.isEmpty) {
      Future.microtask(() => Provider.of<AnswerSheetProvider>(context, listen: false).fetchAnswerSheets(context));
    }

    // Nếu đang loading dữ liệu, show loading indicator
    if (classProvider.isLoading || answerSheetProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final classCodeToName = Provider.of<ClassProvider>(context).classCodeToName;
    print('classCodeToName: ' + classCodeToName.toString());
    for (var c in classProvider.classes) {
      print('Class: code=' + c.class_code + ', name=' + c.class_name);
    }
    String normalizeId(String id) {
      if (id.startsWith('ObjectId(')) {
        return id.substring(9, id.length - 2);
      }
      return id;
    }
    final quizAnswerSheetId = normalizeId(quiz.answersheet);
    print('Normalized quiz answersheet id: ' + quizAnswerSheetId);
    for (var a in answerSheetProvider.answerSheets) {
      print('AnswerSheet: id=' + a.id + ', name=' + a.name + ', filePdf=' + a.filePdf);
    }
    final answerSheetList = answerSheetProvider.answerSheets
        .where((a) => a.id == quizAnswerSheetId)
        .toList();
    final answerSheet = answerSheetList.isNotEmpty ? answerSheetList.first : null;
    print('Matched answerSheet: ' + (answerSheet?.id ?? 'null') + ', name: ' + (answerSheet?.name ?? 'null') + ', filePdf: ' + (answerSheet?.filePdf ?? 'null'));
    final answerSheetName = answerSheet?.name ?? quiz.answersheet;
    final numQuestions = answerSheet?.numQuestions?.toString() ?? '--';
    final filePdf = answerSheet?.filePdf ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Quiz Menu',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 2,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFF2E7D32),
            labelColor: Color(0xFF2E7D32),
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            tabs: [
              Tab(text: 'DETAILS'),
              Tab(text: 'STATISTICS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // DETAILS TAB
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Name',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      quiz.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Classes', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    quiz.class_codes.map((code) => classCodeToName[code] ?? code).join(', '),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Answer Sheet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    answerSheetName,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (filePdf.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.print, color: Color(0xFF2E7D32)),
                                    tooltip: 'Print Answer Sheet',
                                    onPressed: () => _showPrintOptions(context, filePdf),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Date', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                const SizedBox(width: 16),
                                Text(
                                  quiz.date,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Papers', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                const SizedBox(width: 16),
                                Text(
                                  (quiz.papers?.length ?? 0).toString(),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Questions', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                const SizedBox(width: 16),
                                Text(
                                  numQuestions,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('SCAN PAPERS'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                                foregroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 18),
                              ),
                              onPressed: null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.image_search),
                              label: const Text('REVIEW PAPERS'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                                foregroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 18),
                              ),
                              onPressed: null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.bar_chart),
                              label: const Text('ITEM ANALYSIS'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                                foregroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 18),
                              ),
                              onPressed: null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // STATISTICS TAB
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Score Percent',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildStatRow('Min. Score', '--', '--'),
                            _buildStatRow('Max. Score', '--', '--'),
                            _buildStatRow('Average', '--', '--'),
                            _buildStatRow('Median', '--', '--'),
                            _buildStatRow('Std. Deviation', '--', '--'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.camera_alt, color: Colors.white),
                              label: const Text('SCAN PAPERS', style: TextStyle(color: Colors.white),),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 18),
                              ),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.image_search, color: Colors.white,),
                              label: const Text('REVIEW PAPERS', style: TextStyle(color: Colors.white),),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 18),
                              ),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.bar_chart, color: Colors.white),
                              label: const Text('ITEM ANALYSIS', style: TextStyle(color: Colors.white),),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 18),
                              ),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatRow(String label, String score, String percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Row(
            children: [
              Text(score, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 24),
              Text(percent, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
