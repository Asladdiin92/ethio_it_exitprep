import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  static const modules = [
    ('C01', 'Programming', 'Year 2  •  Semester 1', '12 Notes  •  60 Flashcards', Icons.code_rounded, Color(0xFF0F7A51)),
    ('C04', 'Database Systems', 'Year 2  •  Semester 2', '10 Notes  •  45 Flashcards', Icons.storage_rounded, Color(0xFF2C8C86)),
    ('C10', 'Web & Mobile Development', 'Year 3  •  Semester 2', '10 Notes  •  50 Flashcards', Icons.devices_rounded, Color(0xFF3678A6)),
    ('C07', 'Networking & Security', 'Year 3  •  Semester 1', '13 Notes  •  65 Flashcards', Icons.account_tree_rounded, Color(0xFF9A6A20)),
    ('C09', 'System Administration', 'Year 3  •  Semester 1', '8 Notes  •  40 Flashcards', Icons.settings_suggest_rounded, Color(0xFF6D5A9B)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Course modules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Offline reading and practice', style: TextStyle(fontSize: 11, color: Color(0xFF6C7A73))),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('Choose a course', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text('Read focused notes, save key concepts, and quiz yourself immediately.', style: TextStyle(color: Color(0xFF69766F))),
          const SizedBox(height: 18),
          ...modules.map((module) => _ModuleCard(module: module)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) context.go('/exam');
          if (index == 2) context.go('/exam/session');
          if (index == 3) context.go('/analytics');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Modules'),
          NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer_rounded), label: 'Mock exam'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Analytics'),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final (String, String, String, String, IconData, Color) module;

  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/study/course/${module.$1}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: module.$6.withValues(alpha: 0.12), child: Icon(module.$5, color: module.$6, size: 21)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.$2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(module.$3, style: const TextStyle(fontSize: 11, color: Color(0xFF718078))),
                    const SizedBox(height: 3),
                    Text(module.$4, style: TextStyle(fontSize: 11, color: module.$6, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: Color(0xFF829089)),
            ],
          ),
        ),
      ),
    );
  }
}
