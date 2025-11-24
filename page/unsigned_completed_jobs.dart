// import 'package:flutter/material.dart';
// import '../class/job.dart';
// import 'mock_data_service.dart';
// import '../tracker/signature.dart'; // DigitalSignOffPage(job: ...)
//
// class UnsignedCompletedJobsPage extends StatelessWidget {
//   const UnsignedCompletedJobsPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final List<Job> jobs = MockDataService
//         .getJobs()
//         .where((j) => j.status.toLowerCase() == 'repaired' && !j.isSigned)
//         .toList();
//     // 以后有 isSigned 时改成：
//     // .where((j) => j.status.toLowerCase() == 'completed' && !j.isSigned)
//     // .toList();
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Completed but Unsigned')),
//       body: jobs.isEmpty
//           ? const Center(child: Text('No completed unsigned jobs.'))
//           : ListView.separated(
//         itemCount: jobs.length,
//         separatorBuilder: (_, __) => const Divider(height: 1),
//         itemBuilder: (context, index) {
//           final job = jobs[index];
//           return ListTile(
//             title: Text(job.customerName),
//             subtitle: Text('${job.vehicle}\n${job.jobDescription}'),
//             isThreeLine: true,
//             trailing: const Icon(Icons.chevron_right),
//             onTap: () async {
//               // 进入签名页（建议传入 job）
//               await Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => DigitalSignOffPage(job: job),
//                 ),
//               );
//               if (context.mounted) {
//                 (context as Element).markNeedsBuild(); // 返回后刷新
//               }
//             },
//           );
//         },
//       ),
//     );
//   }
// }
