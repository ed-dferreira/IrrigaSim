import 'package:flutter/material.dart';

/// Sub-título + linhas dentro da seção "Dados do sulco".
class DetailSubSection extends StatelessWidget {
  const DetailSubSection({super.key, required this.title, required this.rows});
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 6),
        ...rows,
      ],
    );
  }
}
