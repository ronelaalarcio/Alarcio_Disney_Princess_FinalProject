class Princess {
  final int id;
  final String name;
  final String description;
  final String imageUrl;

  Princess({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
  });
}

final List<Princess> princesses = [
  Princess(
    id: 0,
    name: 'Anna',
    description: 'The adventurous princess of Arendelle who loves her sister Elsa deeply',
    imageUrl: 'assets/icons/anna.jpg',
  ),
  Princess(
    id: 1,
    name: 'Belle',
    description: 'The bookish and brave princess who loves adventure and knowledge',
    imageUrl: 'assets/icons/belle.jpg',
  ),
  Princess(
    id: 2,
    name: 'Ariel',
    description: 'The curious mermaid princess who dreams of living on land',
    imageUrl: 'assets/icons/ariel.jpg',
  ),
  Princess(
    id: 3,
    name: 'Cinderella',
    description: 'The graceful princess who overcame hardship with kindness',
    imageUrl: 'assets/icons/cinderella.jpg',
  ),
  Princess(
    id: 4,
    name: 'Jasmine',
    description: 'The bold princess of Agrabah who values freedom above all',
    imageUrl: 'assets/icons/jasmine.jpg',
  ),
  Princess(
    id: 5,
    name: 'Mulan',
    description: 'The courageous warrior princess who saved China with her bravery',
    imageUrl: 'assets/icons/mulan.jpg',
  ),
  Princess(
    id: 6,
    name: 'Rapunzel',
    description: 'The creative princess with magical golden hair who seeks adventure',
    imageUrl: 'assets/icons/rapunzel.jpg',
  ),
  Princess(
    id: 7,
    name: 'Moana',
    description: 'The determined ocean explorer who saved her people with courage',
    imageUrl: 'assets/icons/moana.png',
  ),
  Princess(
    id: 8,
    name: 'Elsa',
    description: 'The powerful ice queen of Arendelle with a heart of gold',
    imageUrl: 'assets/icons/elsa.jpg',
  ),
  Princess(
    id: 9,
    name: 'Merida',
    description: 'The independent Scottish princess skilled with a bow and arrow',
    imageUrl: 'assets/icons/merida.jpg',
  ),
];