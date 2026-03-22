import 'package:flutter/material.dart';

class TaskCategory {
  final String id;
  final String label;
  final IconData icon;
  final String greeting;

  const TaskCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.greeting,
  });

  static const List<TaskCategory> categories = [
    TaskCategory(
      id: 'tv',
      label: 'TV',
      icon: Icons.tv,
      greeting: 'Hallo! Ik help u graag met uw televisie. Welk merk TV heeft u?',
    ),
    TaskCategory(
      id: 'internet',
      label: 'Internet',
      icon: Icons.wifi,
      greeting:
          'Hallo! Ik help u graag met het internet. Heeft u een nieuw modem ontvangen, of werkt uw internet niet meer?',
    ),
    TaskCategory(
      id: 'telefoon',
      label: 'Telefoon',
      icon: Icons.phone_android,
      greeting:
          'Hallo! Ik help u graag met uw telefoon. Heeft u een smartphone (zoals Samsung of iPhone) of een gewone telefoon?',
    ),
    TaskCategory(
      id: 'anders',
      label: 'Andere vraag',
      icon: Icons.help_outline,
      greeting: 'Hallo! Waarmee kan ik u helpen?',
    ),
  ];
}
