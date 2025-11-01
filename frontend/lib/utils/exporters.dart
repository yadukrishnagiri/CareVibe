import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart' as pdfx;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../services/metrics_api.dart';
import 'health_analytics.dart';

String buildCsv(List<HealthMetricDto> data) {
  final headers = [
    'date',
    'weightKg', 'bmi', 'bloodPressure', 'restingHeartRateBpm', 'spo2Percent', 'bodyTemperatureC',
    'sleepDurationHr', 'remSleepHr', 'sleepInterruptions', 'stepCount', 'exerciseDurationMin', 'caloriesBurned',
    'physicalActivityLevel', 'stressLevel', 'smokingStatus', 'alcoholConsumption',
  ];
  final lines = <String>[];
  lines.add(headers.join(','));
  for (final d in data) {
    final row = [
      d.date.toIso8601String(),
      d.weightKg?.toStringAsFixed(1) ?? '',
      d.bmi?.toStringAsFixed(1) ?? '',
      d.bloodPressureMmHg ?? '',
      d.restingHeartRateBpm,
      d.spo2Percent ?? '',
      d.bodyTemperatureC ?? '',
      d.sleepDurationHr.toStringAsFixed(1),
      d.remSleepHr?.toStringAsFixed(1) ?? '',
      d.sleepInterruptions ?? '',
      d.stepCount,
      d.exerciseDurationMin ?? '',
      d.caloriesBurned ?? '',
      d.physicalActivityLevel ?? '',
      d.stressLevel ?? '',
      d.smokingStatus ?? '',
      d.alcoholConsumption ?? '',
    ];
    lines.add(row.map((e) => '"$e"').join(','));
  }
  return lines.join('\n');
}

Future<void> shareCsv(List<HealthMetricDto> data, {String filename = 'CareVibe_Analytics.csv'}) async {
  final csv = buildCsv(data);
  final bytes = Uint8List.fromList(utf8.encode(csv));
  final file = XFile.fromData(bytes, name: filename, mimeType: 'text/csv');
  await Share.shareXFiles([file], text: 'CareVibe export');
}

Future<Uint8List> buildAnalyticsPdfBytes({required AnalyticsSummary summary, required List<HealthMetricDto> data, String title = 'CareVibe Analytics Report'}) async {
  final doc = pw.Document();

  List<pw.Widget> _metricsTable() {
    return [
      pw.Table(
        border: pw.TableBorder.all(color: pdfx.PdfColors.grey200, width: 0.6),
        children: [
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Wellness')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${summary.wellnessScore.toStringAsFixed(0)}/100')),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Activity Score')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(summary.activityScore.toStringAsFixed(0))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Sleep SQI')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(summary.sleepQualityIndex.isNaN ? '—' : summary.sleepQualityIndex.toStringAsFixed(0))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('REM %')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(summary.remPercent.isNaN ? '—' : '${summary.remPercent.toStringAsFixed(0)}%')),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('MAP / Pulse Pressure')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${summary.map.isNaN ? '—' : summary.map.toStringAsFixed(0)} / ${summary.pulsePressure.isNaN ? '—' : summary.pulsePressure.toStringAsFixed(0)} mmHg')),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('BP Category')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(summary.bpCategory)),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Active Minutes (7d)')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${weeklyActiveMinutes(data)}')),
          ]),
        ],
      ),
    ];
  }

  final notes = clinicianSummary(summary, data);

  doc.addPage(
    pw.MultiPage(
      pageFormat: pdfx.PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => [
        pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text('Date range: last ${data.length} days'),
        pw.SizedBox(height: 16),
        ..._metricsTable(),
        if (notes.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          pw.Text('Clinician Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Column(children: [for (final n in notes) pw.Bullet(text: n)]),
        ],
        if (summary.alerts.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          pw.Text('Alerts', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Column(children: [for (final a in summary.alerts) pw.Bullet(text: a.message)]),
        ],
      ],
    ),
  );

  return doc.save();
}

Future<void> shareAnalyticsPdf({required AnalyticsSummary summary, required List<HealthMetricDto> data}) async {
  final bytes = await buildAnalyticsPdfBytes(summary: summary, data: data);
  await Printing.sharePdf(bytes: bytes, filename: 'CareVibe_Analytics.pdf');
}




