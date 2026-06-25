import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/app_state.dart';

import 'dart:async';
import 'dart:math';

class ArcadeScreen extends StatefulWidget {
  const ArcadeScreen({super.key});

  @override
  State<ArcadeScreen> createState() => _ArcadeScreenState();
}

class _ArcadeScreenState extends State<ArcadeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ConfettiController _confettiController;

  // ── Quiz Arena ─────────────────────────────────────────────────────
  int _currentQuizIdx = 0;
  int? _selectedAnswerIdx;
  bool _quizAnswered = false;
  int _quizScore = 0;
  int _quizLives = 3;          // ❤️ 3 lives
  int _quizStreak = 0;         // 🔥 streak counter
  Timer? _quizTimer;
  int _quizTimeLeft = 15;      // ⏱️ 15 seconds per question
  bool _quizTimeOut = false;

  // ── Class Selector ─────────────────────────────────────────────────
  String _selectedClass = 'Class 1';
  final List<String> _classes = List.generate(12, (index) => 'Class ${index + 1}');

  // ── Cognitive Arena ────────────────────────────────────────────────
  int _currentCognitiveLevel = 0;
  bool _cognitiveSolved = false;
  String? _selectedCognitiveChoice;
  Timer? _cognitiveTimer;
  int _cognitiveTimeLeft = 20;  // ⏱️ 20 seconds
  bool _cognitiveTimeOut = false;

  // ── Syntax Builder ─────────────────────────────────────────────────
  int _currentSyntaxLevel = 0;
  bool _syntaxLevelCompleted = false;
  List<String> _assembledSyntax = [];
  List<String> _shuffledSyntaxTiles = []; // shuffled version
  int _syntaxWrongAttempts = 0;           // ❌ wrong compile attempts

  // ── Word Unscramble ────────────────────────────────────────────────
  int _currentUnscrambleLevel = 0;
  List<int> _tappedLetterIndices = [];
  bool _unscrambleCompleted = false;
  int _unscrambleWrongTaps = 0;           // ❌ wrong submit count
  bool _unscrambleShowHint = false;       // hint revealed or not
  int _unscrambleHintsUsed = 0;           // max 2 hints

  List<Map<String, dynamic>> _getQuizQuestions() {
    int classNum = int.tryParse(_selectedClass.replaceAll('Class ', '')) ?? 1;
    switch (classNum) {
      case 1:
        return [
          {'question': 'What is 3 + 2?', 'options': ['4', '5', '6', '3'], 'correctIdx': 1},
          {'question': 'Which is a primary color?', 'options': ['Green', 'Orange', 'Blue', 'Purple'], 'correctIdx': 2},
          {'question': 'Which animal barks?', 'options': ['Cat', 'Dog', 'Lion', 'Cow'], 'correctIdx': 1},
          {'question': 'How many days in a week?', 'options': ['5', '6', '7', '8'], 'correctIdx': 2},
          {'question': 'What sound does a cow make?', 'options': ['Bark', 'Moo', 'Roar', 'Meow'], 'correctIdx': 1},
          {'question': 'Which is the biggest animal?', 'options': ['Dog', 'Cat', 'Elephant', 'Rabbit'], 'correctIdx': 2},
          {'question': 'How many fingers on one hand?', 'options': ['4', '5', '6', '3'], 'correctIdx': 1},
          {'question': 'What is 1 + 1?', 'options': ['1', '2', '3', '4'], 'correctIdx': 1},
          {'question': 'Which fruit is red?', 'options': ['Banana', 'Apple', 'Mango', 'Grapes'], 'correctIdx': 1},
          {'question': 'How many months are in a year?', 'options': ['10', '11', '12', '13'], 'correctIdx': 2},
        ];
      case 2:
        return [
          {'question': 'What is 12 + 8?', 'options': ['18', '20', '22', '24'], 'correctIdx': 1},
          {'question': 'Where does a fish live?', 'options': ['Land', 'Tree', 'Water', 'Sky'], 'correctIdx': 2},
          {'question': 'Which shape has 3 sides?', 'options': ['Square', 'Circle', 'Triangle', 'Rectangle'], 'correctIdx': 2},
          {'question': 'What is 15 - 7?', 'options': ['6', '7', '8', '9'], 'correctIdx': 2},
          {'question': 'Which bird cannot fly?', 'options': ['Parrot', 'Sparrow', 'Penguin', 'Eagle'], 'correctIdx': 2},
          {'question': 'How many sides does a square have?', 'options': ['3', '4', '5', '6'], 'correctIdx': 1},
          {'question': 'What is the capital of India?', 'options': ['Mumbai', 'Delhi', 'Kolkata', 'Chennai'], 'correctIdx': 1},
          {'question': 'Which is the largest ocean?', 'options': ['Atlantic', 'Indian', 'Pacific', 'Arctic'], 'correctIdx': 2},
          {'question': 'What is 4 × 3?', 'options': ['10', '11', '12', '13'], 'correctIdx': 2},
          {'question': 'Which planet is closest to the Sun?', 'options': ['Earth', 'Venus', 'Mars', 'Mercury'], 'correctIdx': 3},
        ];
      case 3:
        return [
          {'question': 'What is 5 × 4?', 'options': ['15', '20', '25', '30'], 'correctIdx': 1},
          {'question': 'Which of these is a Noun?', 'options': ['Run', 'Beautiful', 'Delhi', 'Quickly'], 'correctIdx': 2},
          {'question': 'How many hours in a day?', 'options': ['12', '24', '48', '36'], 'correctIdx': 1},
          {'question': 'What is 48 ÷ 6?', 'options': ['6', '7', '8', '9'], 'correctIdx': 2},
          {'question': 'Which gas do plants absorb?', 'options': ['Oxygen', 'Nitrogen', 'CO2', 'Helium'], 'correctIdx': 2},
          {'question': 'What is the plural of "child"?', 'options': ['Childs', 'Childes', 'Children', 'Childrens'], 'correctIdx': 2},
          {'question': 'Which is the longest river in India?', 'options': ['Yamuna', 'Ganga', 'Godavari', 'Brahmaputra'], 'correctIdx': 1},
          {'question': 'What is 9 × 9?', 'options': ['72', '81', '90', '63'], 'correctIdx': 1},
          {'question': 'How many sides does a hexagon have?', 'options': ['5', '6', '7', '8'], 'correctIdx': 1},
          {'question': 'Which is an adjective? "The big dog runs fast."', 'options': ['dog', 'runs', 'fast', 'big'], 'correctIdx': 3},
        ];
      case 4:
        return [
          {'question': 'What is 36 ÷ 6?', 'options': ['4', '5', '6', '7'], 'correctIdx': 2},
          {'question': 'Which state of matter is water at room temp?', 'options': ['Solid', 'Liquid', 'Gas', 'Plasma'], 'correctIdx': 1},
          {'question': 'How many days in a leap year?', 'options': ['365', '366', '360', '364'], 'correctIdx': 1},
          {'question': 'What is the Roman numeral for 50?', 'options': ['X', 'L', 'C', 'V'], 'correctIdx': 1},
          {'question': 'Which organ pumps blood in the body?', 'options': ['Lungs', 'Kidney', 'Heart', 'Liver'], 'correctIdx': 2},
          {'question': 'What is LCM of 4 and 6?', 'options': ['8', '10', '12', '16'], 'correctIdx': 2},
          {'question': 'Who wrote the National Anthem of India?', 'options': ['Bankim Chandra', 'Rabindranath Tagore', 'Premchand', 'Kabir'], 'correctIdx': 1},
          {'question': 'What is 7 × 8?', 'options': ['54', '56', '58', '60'], 'correctIdx': 1},
          {'question': 'Which is the smallest prime number?', 'options': ['0', '1', '2', '3'], 'correctIdx': 2},
          {'question': 'What does a plant need to make food?', 'options': ['Moon + Water', 'Sunlight + CO2 + Water', 'Rain + Wind', 'Soil + Fire'], 'correctIdx': 1},
        ];
      case 5:
        return [
          {'question': 'What is 0.5 + 0.25?', 'options': ['0.75', '0.80', '0.65', '0.70'], 'correctIdx': 0},
          {'question': 'Which is the largest planet?', 'options': ['Earth', 'Mars', 'Jupiter', 'Saturn'], 'correctIdx': 2},
          {'question': 'Choose the pronoun: "She is reading."', 'options': ['She', 'reading', 'is', 'a'], 'correctIdx': 0},
          {'question': 'What is the HCF of 12 and 18?', 'options': ['4', '6', '9', '12'], 'correctIdx': 1},
          {'question': 'Which gas makes up most of Earth\'s atmosphere?', 'options': ['Oxygen', 'CO2', 'Nitrogen', 'Argon'], 'correctIdx': 2},
          {'question': 'What is 25% of 200?', 'options': ['25', '50', '75', '100'], 'correctIdx': 1},
          {'question': 'Which country is known as the "Land of Rising Sun"?', 'options': ['China', 'India', 'Japan', 'Korea'], 'correctIdx': 2},
          {'question': 'What is the area of a rectangle 5×4?', 'options': ['16', '18', '20', '22'], 'correctIdx': 2},
          {'question': 'Name the process by which plants make food:', 'options': ['Respiration', 'Digestion', 'Photosynthesis', 'Transpiration'], 'correctIdx': 2},
          {'question': 'What is 2³ (2 cubed)?', 'options': ['6', '8', '9', '12'], 'correctIdx': 1},
        ];
      case 6:
        return [
          {'question': 'Find x: x - 4 = 10', 'options': ['6', '12', '14', '16'], 'correctIdx': 2},
          {'question': 'Which pigment gives plants green color?', 'options': ['Carotene', 'Chlorophyll', 'Xanthophyll', 'Melanin'], 'correctIdx': 1},
          {'question': 'A 90 degree angle is called:', 'options': ['Acute', 'Obtuse', 'Right', 'Straight'], 'correctIdx': 2},
          {'question': 'What is the ratio 3:9 in simplest form?', 'options': ['1:2', '1:3', '2:3', '3:9'], 'correctIdx': 1},
          {'question': 'Who discovered gravity?', 'options': ['Einstein', 'Newton', 'Galileo', 'Edison'], 'correctIdx': 1},
          {'question': 'What is the perimeter of a square with side 5?', 'options': ['10', '15', '20', '25'], 'correctIdx': 2},
          {'question': 'Which type of rock is formed by cooling lava?', 'options': ['Sedimentary', 'Metamorphic', 'Igneous', 'Fossil'], 'correctIdx': 2},
          {'question': 'What is the value of π (pi) approx?', 'options': ['2.14', '3.14', '4.14', '1.14'], 'correctIdx': 1},
          {'question': 'Identify the verb: "She sings beautifully."', 'options': ['She', 'sings', 'beautifully', 'the'], 'correctIdx': 1},
          {'question': 'What is 15% of 60?', 'options': ['6', '7', '8', '9'], 'correctIdx': 3},
        ];
      case 7:
        return [
          {'question': 'What is (-5) + (-8)?', 'options': ['-13', '13', '-3', '3'], 'correctIdx': 0},
          {'question': 'Where does chemical digestion of protein start?', 'options': ['Mouth', 'Stomach', 'Small Intestine', 'Esophagus'], 'correctIdx': 1},
          {'question': 'Who was the first Prime Minister of India?', 'options': ['Gandhi', 'Nehru', 'Bose', 'Ambedkar'], 'correctIdx': 1},
          {'question': 'What is the formula for speed?', 'options': ['Speed = Distance × Time', 'Speed = Distance ÷ Time', 'Speed = Time ÷ Distance', 'Speed = Mass × Velocity'], 'correctIdx': 1},
          {'question': 'What is the square root of 144?', 'options': ['10', '11', '12', '13'], 'correctIdx': 2},
          {'question': 'Which is the hardest natural substance?', 'options': ['Iron', 'Gold', 'Diamond', 'Platinum'], 'correctIdx': 2},
          {'question': 'Solve: 3x + 6 = 15, x = ?', 'options': ['2', '3', '4', '5'], 'correctIdx': 1},
          {'question': 'In which continent is the Amazon rainforest?', 'options': ['Africa', 'Asia', 'South America', 'Australia'], 'correctIdx': 2},
          {'question': 'What is the median of: 3, 5, 7, 9, 11?', 'options': ['5', '6', '7', '9'], 'correctIdx': 2},
          {'question': 'Photosynthesis takes place in which part of the plant?', 'options': ['Root', 'Stem', 'Leaf', 'Flower'], 'correctIdx': 2},
        ];
      case 8:
        return [
          {'question': 'What is √196?', 'options': ['12', '13', '14', '15'], 'correctIdx': 2},
          {'question': 'Chemical symbol for Gold?', 'options': ['Ag', 'Fe', 'Au', 'Cu'], 'correctIdx': 2},
          {'question': 'Solve: 2y + 5 = 15', 'options': ['3', '5', '10', '4'], 'correctIdx': 1},
          {'question': 'What is the full form of DNA?', 'options': ['Deoxyribose Nucleic Acid', 'Deoxyribonucleic Acid', 'Dinucleic Acid', 'Dinitrogen Acid'], 'correctIdx': 1},
          {'question': 'Which law states F = ma?', 'options': ['Newton\'s 1st Law', 'Newton\'s 2nd Law', 'Newton\'s 3rd Law', 'Boyle\'s Law'], 'correctIdx': 1},
          {'question': 'What is a quadrilateral with all sides equal?', 'options': ['Rectangle', 'Rhombus', 'Trapezium', 'Kite'], 'correctIdx': 1},
          {'question': 'Who was the first Indian to go to space?', 'options': ['APJ Abdul Kalam', 'Rakesh Sharma', 'Sunita Williams', 'Vikram Sarabhai'], 'correctIdx': 1},
          {'question': 'What is the SI unit of Force?', 'options': ['Joule', 'Watt', 'Newton', 'Pascal'], 'correctIdx': 2},
          {'question': 'If a = 4, what is a² + 2a?', 'options': ['20', '22', '24', '28'], 'correctIdx': 2},
          {'question': 'Which gas is produced during photosynthesis?', 'options': ['CO2', 'Oxygen', 'Nitrogen', 'Hydrogen'], 'correctIdx': 1},
        ];
      case 9:
        return [
          {'question': 'Which organelle is the powerhouse of the cell?', 'options': ['Nucleus', 'Mitochondria', 'Ribosome', 'Golgi body'], 'correctIdx': 1},
          {'question': 'Newton\'s 1st Law is also called?', 'options': ['Law of Action-Reaction', 'Law of Inertia', 'Law of Acceleration', 'Gravitation'], 'correctIdx': 1},
          {'question': 'Degree of polynomial x³ + 5x² - 4x + 7?', 'options': ['1', '2', '3', '4'], 'correctIdx': 2},
          {'question': 'Which acid is found in vinegar?', 'options': ['Citric Acid', 'Acetic Acid', 'Lactic Acid', 'Formic Acid'], 'correctIdx': 1},
          {'question': 'What is the HCF of 36 and 48?', 'options': ['6', '8', '12', '16'], 'correctIdx': 2},
          {'question': 'Where are genes located in a cell?', 'options': ['Cell membrane', 'Cytoplasm', 'Chromosome', 'Ribosome'], 'correctIdx': 2},
          {'question': 'Solve: (x-2)(x+3) = 0, values of x?', 'options': ['x=2, x=3', 'x=2, x=-3', 'x=-2, x=3', 'x=-2, x=-3'], 'correctIdx': 1},
          {'question': 'What is the distance formula between (0,0) and (3,4)?', 'options': ['3', '4', '5', '7'], 'correctIdx': 2},
          {'question': 'Ohm\'s law states: V = ?', 'options': ['I + R', 'I × R', 'I ÷ R', 'I - R'], 'correctIdx': 1},
          {'question': 'Which blood group is universal donor?', 'options': ['A', 'B', 'AB', 'O'], 'correctIdx': 3},
        ];
      case 10:
        return [
          {'question': 'If sin(θ) = 4/5, what is cos(θ)?', 'options': ['3/5', '1/5', '2/5', '4/3'], 'correctIdx': 0},
          {'question': 'Atomic number 6 = which element?', 'options': ['Hydrogen', 'Helium', 'Carbon', 'Oxygen'], 'correctIdx': 2},
          {'question': 'SI unit of electric resistance?', 'options': ['Ampere', 'Volt', 'Ohm', 'Watt'], 'correctIdx': 2},
          {'question': 'What is tan(45°)?', 'options': ['0', '1', '√2', '√3/2'], 'correctIdx': 1},
          {'question': 'Which acid is in the human stomach?', 'options': ['Sulphuric Acid', 'Nitric Acid', 'Hydrochloric Acid', 'Citric Acid'], 'correctIdx': 2},
          {'question': 'Solve: x² - 5x + 6 = 0', 'options': ['x=1,6', 'x=2,3', 'x=3,4', 'x=-2,-3'], 'correctIdx': 1},
          {'question': 'What is the EMF unit?', 'options': ['Ohm', 'Watt', 'Volt', 'Ampere'], 'correctIdx': 2},
          {'question': 'Chemical formula of water?', 'options': ['HO', 'H2O', 'H2O2', 'OH'], 'correctIdx': 1},
          {'question': 'Surface area of sphere formula?', 'options': ['πr²', '2πr', '4πr²', '(4/3)πr³'], 'correctIdx': 2},
          {'question': 'Who wrote "The Republic"?', 'options': ['Socrates', 'Aristotle', 'Plato', 'Cicero'], 'correctIdx': 2},
        ];
      case 11:
        return [
          {'question': 'Dot product of two perpendicular vectors?', 'options': ['1', '0', '-1', 'Infinity'], 'correctIdx': 1},
          {'question': 'Electron sharing bond is called?', 'options': ['Ionic', 'Covalent', 'Metallic', 'Hydrogen'], 'correctIdx': 1},
          {'question': 'General formula of Alkanes?', 'options': ['CnH2n', 'CnH2n-2', 'CnH2n+2', 'CnHn'], 'correctIdx': 2},
          {'question': 'Derivative of sin(x)?', 'options': ['-cos(x)', 'cos(x)', 'tan(x)', '-sin(x)'], 'correctIdx': 1},
          {'question': 'Which law relates P, V, T of gas? PV=nRT is called?', 'options': ['Boyle\'s Law', 'Charles\' Law', 'Avogadro\'s Law', 'Ideal Gas Law'], 'correctIdx': 3},
          {'question': 'What is the electric field unit?', 'options': ['N/m', 'N/C', 'J/C', 'C/m'], 'correctIdx': 1},
          {'question': 'Limit of sin(x)/x as x→0?', 'options': ['0', '∞', '1', 'undefined'], 'correctIdx': 2},
          {'question': 'Number of valence electrons in Carbon?', 'options': ['2', '4', '6', '8'], 'correctIdx': 1},
          {'question': 'Speed of light in vacuum (approx)?', 'options': ['3×10⁶ m/s', '3×10⁸ m/s', '3×10¹⁰ m/s', '3×10⁴ m/s'], 'correctIdx': 1},
          {'question': 'Which theorem: a²+b²=c² in right triangle?', 'options': ['Fermat\'s', 'Euclid\'s', 'Pythagoras\'', 'Thales\''], 'correctIdx': 2},
        ];
      case 12:
      default:
        return [
          {'question': '∫ (1/x) dx = ?', 'options': ['e^x + C', 'ln|x| + C', '-1/x² + C', 'x²/2 + C'], 'correctIdx': 1},
          {'question': 'AND gate output 1 only when?', 'options': ['Both 0', 'Both 1', 'Any 1', 'Neither'], 'correctIdx': 1},
          {'question': 'SI unit of electric flux?', 'options': ['Tesla', 'Weber', 'N·m²/C', 'Coulomb'], 'correctIdx': 2},
          {'question': 'd/dx(e^x) = ?', 'options': ['xe^(x-1)', 'e^x', 'ln(x)', '1/x'], 'correctIdx': 1},
          {'question': 'Which data structure uses LIFO?', 'options': ['Queue', 'Stack', 'Array', 'Tree'], 'correctIdx': 1},
          {'question': 'Planck\'s constant h ≈ ?', 'options': ['6.63×10⁻³⁴ Js', '6.63×10⁻²⁴ Js', '6.63×10³⁴ Js', '3.14×10⁻³⁴ Js'], 'correctIdx': 0},
          {'question': 'Binary of decimal 10?', 'options': ['1000', '1010', '1100', '0110'], 'correctIdx': 1},
          {'question': 'Entropy is measured in?', 'options': ['Joule/kg', 'J/K', 'W/m', 'Pascal'], 'correctIdx': 1},
          {'question': 'P-type semiconductor doped with?', 'options': ['Phosphorus', 'Arsenic', 'Boron', 'Nitrogen'], 'correctIdx': 2},
          {'question': '∫ e^x dx = ?', 'options': ['e^(x+1)/(x+1)', 'e^x + C', 'xe^x + C', '1/e^x + C'], 'correctIdx': 1},
        ];
    }
  }

  List<Map<String, dynamic>> _getCognitiveLevels() {
    final List<Map<String, dynamic>> baseLevels;
    int classNum = int.tryParse(_selectedClass.replaceAll('Class ', '')) ?? 1;
    switch (classNum) {
      case 1:
        baseLevels = [
          {
            'type': 'spatial',
            'question': 'Shape Identical Challenge: Choose the matching rotated shape for ▲ turned upside down (180°):',
            'original': '▲',
            'choices': ['▲', '▼', '◀', '▶'],
            'correct': '▼',
            'desc': 'Symmetry Match. 180° turns the top-pointer upside down!',
          },
          {
            'type': 'spatial',
            'question': 'Symmetry Match: Find the mirrored shape for ◀:',
            'original': '◀',
            'choices': ['▲', '▼', '◀', '▶'],
            'correct': '▶',
            'desc': 'Mirroring flips left to right.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 5:',
            'choices': ['3 + 2', '2 + 1', '4 + 3', '1 + 1'],
            'correct': '3 + 2',
            'desc': 'Basic addition: 3 + 2 = 5.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 3:',
            'choices': ['2 + 1', '3 + 2', '4 + 0', '1 + 0'],
            'correct': '2 + 1',
            'desc': 'Basic addition: 2 + 1 = 3.',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from bottom-left (0,0) to top-left (0,1) in a 2x2 grid:',
            'choices': ['Up', 'Down', 'Right', 'Left'],
            'correct': 'Up',
            'desc': 'Move one step Up to reach (0,1).',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from bottom-left (0,0) to bottom-right (1,0) in a 2x2 grid:',
            'choices': ['Up', 'Down', 'Right', 'Left'],
            'correct': 'Right',
            'desc': 'Move one step Right to reach (1,0).',
          },
          {
            'type': 'spatial',
            'question': 'Pattern Completion: What comes next in the pattern? ●, ■, ●, ■, [?]',
            'choices': ['●', '■', '▲', '★'],
            'correct': '●',
            'desc': 'The pattern alternates between circle and square.',
          },
          {
            'type': 'spatial',
            'question': 'Pattern Completion: What comes next in the pattern? ▲, ▲, ●, ▲, ▲, [?]',
            'choices': ['▲', '●', '■', '★'],
            'correct': '●',
            'desc': 'The pattern repeats: two triangles followed by one circle.',
          },
          {
            'type': 'spatial',
            'question': 'Odd One Out: Find the shape that does not match the others:',
            'choices': ['▲', '■', '●', '✹'],
            'correct': '✹',
            'desc': 'The star (✹) is spiked, while others are basic shapes.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 2.',
            'input': 2,
            'flow': 'true',
            'choices': ['4', '6', '8', '10'],
            'correct': '6',
            'desc': '2 + 4 = 6. Since 6 > 5, output is 6.',
          }
        ];
        break;
      case 2:
        baseLevels = [
          {
            'type': 'spatial',
            'question': 'Which shape matches a 90° clockwise rotation of ◀?',
            'original': '◀',
            'choices': ['▲', '▼', '◀', '▶'],
            'correct': '▲',
            'desc': 'Rotation Match. 90° clockwise points the arrow UP!',
          },
          {
            'type': 'spatial',
            'question': 'Which shape matches a 90° clockwise rotation of ▲?',
            'original': '▲',
            'choices': ['▲', '▼', '◀', '▶'],
            'correct': '▶',
            'desc': 'Rotating 90° clockwise turns the top-pointer to the right.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 8:',
            'choices': ['5 + 3', '4 + 2', '6 + 1', '7 + 3'],
            'correct': '5 + 3',
            'desc': 'Addition: 5 + 3 = 8.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 10:',
            'choices': ['6 + 4', '5 + 4', '7 + 2', '8 + 1'],
            'correct': '6 + 4',
            'desc': 'Addition: 6 + 4 = 10.',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from bottom-left (0,0) to top-right (1,1) in a 2x2 grid:',
            'choices': ['Up, Right', 'Up, Down', 'Right, Left', 'Right, Right'],
            'correct': 'Up, Right',
            'desc': 'Move Up then Right to reach (1,1).',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from bottom-left (0,0) to top-left (0,2) in a 3x3 grid:',
            'choices': ['Up, Up', 'Up, Right', 'Right, Right', 'Down, Down'],
            'correct': 'Up, Up',
            'desc': 'Move two steps Up to reach (0,2).',
          },
          {
            'type': 'spatial',
            'question': 'Pattern Completion: What comes next? ★, ●, ★, ●, [?]',
            'choices': ['★', '●', '▲', '■'],
            'correct': '★',
            'desc': 'The pattern alternates between star and circle.',
          },
          {
            'type': 'spatial',
            'question': 'Pattern Completion: What comes next? 1, 2, 3, 1, 2, [?]',
            'choices': ['1', '2', '3', '4'],
            'correct': '3',
            'desc': 'The pattern repeats 1, 2, 3.',
          },
          {
            'type': 'spatial',
            'question': 'Odd One Out: Find the fruit that does not belong:',
            'choices': ['Apple', 'Banana', 'Carrot', 'Grape'],
            'correct': 'Carrot',
            'desc': 'Carrot is a vegetable, while the others are fruits.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 4.',
            'input': 4,
            'flow': 'true',
            'choices': ['4', '6', '8', '10'],
            'correct': '8',
            'desc': '4 + 4 = 8. Since 8 > 5, output is 8.',
          }
        ];
        break;
      case 3:
        baseLevels = [
          {
            'type': 'spatial',
            'question': 'Symmetry Match: If ● represents 1 and ●● represents 2, what represents 4?',
            'original': '●●\n●●',
            'choices': ['●', '●●', '●●●', '●●\n●●'],
            'correct': '●●\n●●',
            'desc': 'Visual Patterns. A 2x2 grid contains 4 dots!',
          },
          {
            'type': 'spatial',
            'question': 'Which shape matches a 180° rotation of ▼?',
            'original': '▼',
            'choices': ['▲', '▼', '◀', '▶'],
            'correct': '▲',
            'desc': '180° turns the down-pointer upside down to point UP.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 12:',
            'choices': ['7 + 5', '6 + 5', '8 + 3', '9 + 2'],
            'correct': '7 + 5',
            'desc': 'Addition: 7 + 5 = 12.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 15:',
            'choices': ['9 + 6', '8 + 6', '10 + 4', '7 + 7'],
            'correct': '9 + 6',
            'desc': 'Addition: 9 + 6 = 15.',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from bottom-left (0,0) to top-right (2,2) in a 3x3 grid:',
            'choices': ['Up, Up, Right, Right', 'Up, Right, Up', 'Right, Right, Up', 'Up, Up, Up'],
            'correct': 'Up, Up, Right, Right',
            'desc': 'Move 2 steps Up and 2 steps Right to reach (2,2).',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from bottom-left (0,0) to (1,2) in a 3x3 grid:',
            'choices': ['Up, Up, Right', 'Up, Right, Right', 'Up, Up, Up', 'Right, Right'],
            'correct': 'Up, Up, Right',
            'desc': 'Move 2 steps Up and 1 step Right to reach (1,2).',
          },
          {
            'type': 'spatial',
            'question': 'Pattern Completion: What is the next number? 2, 4, 6, 8, [?]',
            'choices': ['9', '10', '11', '12'],
            'correct': '10',
            'desc': 'The pattern adds 2 each time (even numbers).',
          },
          {
            'type': 'spatial',
            'question': 'Pattern Completion: What is the next number? 5, 10, 15, 20, [?]',
            'choices': ['21', '22', '25', '30'],
            'correct': '25',
            'desc': 'Count by 5s.',
          },
          {
            'type': 'spatial',
            'question': 'Odd One Out: Find the item that does not fly:',
            'choices': ['Eagle', 'Sparrow', 'Penguin', 'Bat'],
            'correct': 'Penguin',
            'desc': 'Penguins are flightless birds, others can fly.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 6.',
            'input': 6,
            'flow': 'true',
            'choices': ['5', '8', '10', '12'],
            'correct': '10',
            'desc': '6 + 4 = 10. Since 10 > 5, output is 10.',
          }
        ];
        break;
      case 4:
        baseLevels = [
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from bottom-left (0,0) to top-right (1,1) in a 2x2 grid:',
            'grid': '2x2',
            'choices': ['Up, Right', 'Up, Down', 'Right, Left', 'Down, Right'],
            'correct': 'Up, Right',
            'desc': 'Pathfinder. Move 1 step Up and 1 step Right to reach (1,1).',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from bottom-left (0,0) to right-edge (2,0) in a 3x3 grid:',
            'choices': ['Right, Right', 'Up, Up', 'Right, Up', 'Left, Left'],
            'correct': 'Right, Right',
            'desc': 'Move 2 steps Right to reach (2,0).',
          },
          {
            'type': 'spatial',
            'question': 'Which shape matches a 180° rotation of L?',
            'original': 'L',
            'choices': ['7', 'J', 'L', 'T'],
            'correct': '7',
            'desc': '180° rotation turns L upside down and faces left, looking like a 7.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 20:',
            'choices': ['12 + 8', '15 + 4', '10 + 9', '11 + 8'],
            'correct': '12 + 8',
            'desc': 'Addition: 12 + 8 = 20.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 25:',
            'choices': ['15 + 10', '12 + 12', '18 + 6', '20 + 4'],
            'correct': '15 + 10',
            'desc': 'Addition: 15 + 10 = 25.',
          },
          {
            'type': 'spatial',
            'question': 'Pattern Completion: What is next? 10, 20, 30, 40, [?]',
            'choices': ['45', '50', '55', '60'],
            'correct': '50',
            'desc': 'Count by 10s.',
          },
          {
            'type': 'spatial',
            'question': 'Pattern Completion: What is next? 3, 6, 9, 12, [?]',
            'choices': ['13', '14', '15', '16'],
            'correct': '15',
            'desc': 'Count by 3s.',
          },
          {
            'type': 'spatial',
            'question': 'Odd One Out: Find the non-programming language word:',
            'choices': ['Python', 'HTML', 'Java', 'Spaghetti'],
            'correct': 'Spaghetti',
            'desc': 'Spaghetti is food, the others are programming/coding languages.',
          },
          {
            'type': 'spatial',
            'question': 'How many vertices does a pentagon have?',
            'choices': ['4', '5', '6', '8'],
            'correct': '5',
            'desc': 'A pentagon has 5 corners/vertices.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 8.',
            'input': 8,
            'flow': 'true',
            'choices': ['5', '6', '8', '10'],
            'correct': '6',
            'desc': '8 + 4 = 12. 12 / 2 = 6. Since 6 > 5, output is 6.',
          }
        ];
        break;
      case 5:
        baseLevels = [
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 12:',
            'target': 12,
            'choices': ['4 + 4 + 4', '5 + 5 + 1', '6 + 3 + 2', '8 + 1 + 2'],
            'correct': '4 + 4 + 4',
            'desc': 'Numerical Bubbles. Pop 3 bubbles of 4 to reach 12!',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 18:',
            'choices': ['6 + 6 + 6', '5 + 5 + 5', '10 + 4 + 2', '8 + 8 + 1'],
            'correct': '6 + 6 + 6',
            'desc': 'Addition: 6 + 6 + 6 = 18.',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from bottom-left (0,0) to top-right (2,2) in a 3x3 grid:',
            'choices': ['Up, Up, Right, Right', 'Up, Right, Up, Right', 'Right, Right, Up, Up', 'All of the above'],
            'correct': 'All of the above',
            'desc': 'All paths correctly end at (2,2).',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from (1,1) to (2,2) in a 3x3 grid:',
            'choices': ['Up, Right', 'Up, Up', 'Right, Right', 'Down, Left'],
            'correct': 'Up, Right',
            'desc': 'Move 1 step Up and 1 step Right to go from (1,1) to (2,2).',
          },
          {
            'type': 'spatial',
            'question': 'Pattern Completion: What is the next number? 1, 3, 6, 10, [?]',
            'choices': ['12', '14', '15', '16'],
            'correct': '15',
            'desc': 'Add 2, then 3, then 4, then 5. 10 + 5 = 15.',
          },
          {
            'type': 'spatial',
            'question': 'Pattern Completion: What is the next number? 2, 4, 8, 16, [?]',
            'choices': ['20', '24', '30', '32'],
            'correct': '32',
            'desc': 'Double the number each time.',
          },
          {
            'type': 'spatial',
            'question': 'Odd One Out: Find the device that is primarily an output device:',
            'choices': ['Keyboard', 'Mouse', 'Monitor', 'Scanner'],
            'correct': 'Monitor',
            'desc': 'Monitor displays output; the others are input devices.',
          },
          {
            'type': 'spatial',
            'question': 'What is the sum of angles in a triangle?',
            'choices': ['90°', '180°', '270°', '360°'],
            'correct': '180°',
            'desc': 'The angles of any triangle always add up to 180 degrees.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 10.',
            'input': 10,
            'flow': 'true',
            'choices': ['5', '7', '9', '11'],
            'correct': '7',
            'desc': '10 + 4 = 14. 14 / 2 = 7. Since 7 > 5, output is 7.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 0.',
            'input': 0,
            'flow': 'true',
            'choices': ['2', '4', '6', '8'],
            'correct': '4',
            'desc': '0 + 4 = 4. 4 / 2 = 2. Since 2 <= 5, output is 2 * 2 = 4.',
          }
        ];
        break;
      case 6:
        baseLevels = [
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from (0,0) to (2,2) in a 3x3 grid:',
            'grid': '3x3',
            'choices': ['Up, Up, Right, Right', 'Up, Right, Down, Up', 'Right, Right, Left, Up', 'Up, Up, Down, Right'],
            'correct': 'Up, Up, Right, Right',
            'desc': 'Pathfinder. Move 2 steps Up and 2 steps Right to reach (2,2).',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from (0,0) to (3,0) in a 4x4 grid:',
            'choices': ['Right, Right, Right', 'Up, Up, Up', 'Right, Right, Up', 'Left, Left, Left'],
            'correct': 'Right, Right, Right',
            'desc': 'Move 3 steps Right to reach (3,0).',
          },
          {
            'type': 'spatial',
            'question': 'Pattern Completion: What comes next? A, C, E, G, [?]',
            'choices': ['H', 'I', 'J', 'K'],
            'correct': 'I',
            'desc': 'Skip one letter each time: A(b)C(d)E(f)G(h)I.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 24:',
            'choices': ['8 + 8 + 8', '7 + 8 + 8', '9 + 9 + 5', '6 + 6 + 10'],
            'correct': '8 + 8 + 8',
            'desc': 'Pop three 8s: 8 * 3 = 24.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 30:',
            'choices': ['10 + 10 + 10', '15 + 5 + 5', '12 + 12 + 6', '9 + 9 + 12'],
            'correct': '10 + 10 + 10',
            'desc': 'Pop three 10s.',
          },
          {
            'type': 'spatial',
            'question': 'Pentagon has 5 sides, Hexagon has 6 sides. How many sides does an Octagon have?',
            'choices': ['6', '7', '8', '10'],
            'correct': '8',
            'desc': 'An octagon has 8 sides.',
          },
          {
            'type': 'spatial',
            'question': 'Odd One Out: Find the element that is NOT a metal at room temp:',
            'choices': ['Iron', 'Gold', 'Copper', 'Oxygen'],
            'correct': 'Oxygen',
            'desc': 'Oxygen is a gas, others are metals.',
          },
          {
            'type': 'spatial',
            'question': 'Which is the mirror image of the lowercase letter "b"?',
            'choices': ['b', 'd', 'p', 'q'],
            'correct': 'd',
            'desc': 'Flips horizontally, "b" becomes "d".',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 12.',
            'input': 12,
            'flow': 'true',
            'choices': ['6', '8', '10', '12'],
            'correct': '8',
            'desc': '12 + 4 = 16. 16 / 2 = 8. Since 8 > 5, output is 8.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 14.',
            'input': 14,
            'flow': 'true',
            'choices': ['7', '9', '11', '13'],
            'correct': '9',
            'desc': '14 + 4 = 18. 18 / 2 = 9. Since 9 > 5, output is 9.',
          }
        ];
        break;
      case 7:
        baseLevels = [
          {
            'type': 'spatial',
            'question': 'Numerical Aptitude: Complete the Fibonacci sequence: 1, 1, 2, 3, 5, 8, [?]',
            'choices': ['11', '12', '13', '14'],
            'correct': '13',
            'desc': 'Numerical Series. Add the last two terms: 5 + 8 = 13.',
          },
          {
            'type': 'spatial',
            'question': 'Numerical Aptitude: What is next in sequence? 1, 4, 9, 16, 25, [?]',
            'choices': ['30', '34', '36', '40'],
            'correct': '36',
            'desc': 'Square numbers: 1², 2², 3², 4², 5², 6² = 36.',
          },
          {
            'type': 'spatial',
            'question': 'Letter Series: What is next? Z, W, T, Q, [?]',
            'choices': ['N', 'O', 'P', 'M'],
            'correct': 'N',
            'desc': 'Go backwards by skipping 2 letters: Z(yx)W(vu)T(sr)Q(po)N.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 40:',
            'choices': ['15 + 15 + 10', '20 + 10 + 5', '12 + 18 + 5', '25 + 10 + 10'],
            'correct': '15 + 15 + 10',
            'desc': 'Pop bubbles: 15 + 15 + 10 = 40.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 21:',
            'choices': ['7 + 7 + 7', '6 + 6 + 9', '10 + 10 + 1', '8 + 8 + 5'],
            'correct': '7 + 7 + 7',
            'desc': 'Pop three 7s: 7 * 3 = 21.',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from bottom-left (0,0) to top-right (3,3) in a 4x4 grid:',
            'choices': ['Up, Up, Up, Right, Right, Right', 'Up, Right, Up, Right', 'Right, Right, Right, Up, Up', 'Both 1 and 3'],
            'correct': 'Both 1 and 3',
            'desc': 'Both options move 3 steps Up and 3 steps Right to reach (3,3).',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from bottom-left (0,0) to (1,3) in a 4x4 grid:',
            'choices': ['Up, Up, Up, Right', 'Up, Up, Right, Right', 'Up, Right, Right, Right', 'Right, Right, Right'],
            'correct': 'Up, Up, Up, Right',
            'desc': 'Move 3 steps Up and 1 step Right to reach (1,3).',
          },
          {
            'type': 'spatial',
            'question': 'Odd One Out: Which tool is NOT used for measuring length?',
            'choices': ['Ruler', 'Tape Measure', 'Thermometer', 'Caliper'],
            'correct': 'Thermometer',
            'desc': 'Thermometer measures temperature, others measure length.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 16.',
            'input': 16,
            'flow': 'true',
            'choices': ['8', '10', '12', '14'],
            'correct': '10',
            'desc': '16 + 4 = 20. 20 / 2 = 10. Since 10 > 5, output is 10.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 18.',
            'input': 18,
            'flow': 'true',
            'choices': ['9', '11', '13', '15'],
            'correct': '11',
            'desc': '18 + 4 = 22. 22 / 2 = 11. Since 11 > 5, output is 11.',
          }
        ];
        break;
      case 8:
        baseLevels = [
          {
            'type': 'spatial',
            'question': 'Stack Challenge: Stack holds [10]. If you push 20, push 30, and pop once, what is on top?',
            'choices': ['10', '20', '30', 'Empty'],
            'correct': '20',
            'desc': 'LIFO Order. Pop removes 30 (the last element), leaving 20 on top.',
          },
          {
            'type': 'spatial',
            'question': 'Queue Challenge: Queue has [10]. If you enqueue 20, enqueue 30, and dequeue once, what is at the front?',
            'choices': ['10', '20', '30', 'Empty'],
            'correct': '20',
            'desc': 'FIFO Order. Dequeue removes 10 (the first element), leaving 20 at the front.',
          },
          {
            'type': 'spatial',
            'question': 'Pattern Completion: What is next? 2, 6, 12, 20, [?]',
            'choices': ['24', '28', '30', '32'],
            'correct': '30',
            'desc': 'Add 4, then 6, then 8, then 10. 20 + 10 = 30.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 50:',
            'choices': ['20 + 20 + 10', '30 + 10 + 5', '15 + 15 + 15', '25 + 25 + 5'],
            'correct': '20 + 20 + 10',
            'desc': 'Addition: 20 + 20 + 10 = 50.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 14:',
            'choices': ['5 + 5 + 4', '6 + 6 + 3', '8 + 4 + 1', '7 + 7 + 1'],
            'correct': '5 + 5 + 4',
            'desc': 'Addition: 5 + 5 + 4 = 14.',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from bottom-left (0,0) to (2,1) in a 3x3 grid:',
            'choices': ['Up, Right, Right', 'Up, Up, Right', 'Right, Right, Up', 'Right, Up, Up'],
            'correct': 'Right, Right, Up',
            'desc': 'Move 2 steps Right and 1 step Up to reach (2,1).',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from (1,1) to (3,3) in a 4x4 grid:',
            'choices': ['Up, Up, Right, Right', 'Up, Right, Down', 'Right, Right, Down', 'Up, Up, Up'],
            'correct': 'Up, Up, Right, Right',
            'desc': 'Move 2 steps Up and 2 steps Right to reach (3,3).',
          },
          {
            'type': 'spatial',
            'question': 'How many vertices does a standard cube have?',
            'choices': ['6', '8', '12', '16'],
            'correct': '8',
            'desc': 'A cube has 8 corners/vertices.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 20.',
            'input': 20,
            'flow': 'true',
            'choices': ['10', '12', '14', '16'],
            'correct': '12',
            'desc': '20 + 4 = 24. 24 / 2 = 12. Since 12 > 5, output is 12.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 6.',
            'input': 6,
            'flow': 'true',
            'choices': ['5', '8', '10', '12'],
            'correct': '10',
            'desc': '6 + 4 = 10. 10 / 2 = 5. Since 5 <= 5, output is 5 * 2 = 10.',
          }
        ];
        break;
      case 9:
        baseLevels = [
          {
            'type': 'spatial',
            'question': 'Queue Challenge: Queue has [40, 50]. Enqueue 60, dequeue once, what is at the front?',
            'choices': ['40', '50', '60', 'Empty'],
            'correct': '50',
            'desc': 'FIFO. Dequeue removes 40, leaving 50 at the front.',
          },
          {
            'type': 'spatial',
            'question': 'Stack Challenge: Stack has [40, 50]. Push 60, pop once, what is on top?',
            'choices': ['40', '50', '60', 'Empty'],
            'correct': '50',
            'desc': 'LIFO. Pop removes 60, leaving 50 on top.',
          },
          {
            'type': 'spatial',
            'question': 'Number Series: What is the next prime number? 2, 3, 5, 7, 11, [?]',
            'choices': ['12', '13', '15', '17'],
            'correct': '13',
            'desc': '13 is the next prime number.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 60:',
            'choices': ['25 + 25 + 10', '30 + 20 + 5', '20 + 20 + 10', '35 + 15 + 5'],
            'correct': '25 + 25 + 10',
            'desc': 'Addition: 25 + 25 + 10 = 60.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 36:',
            'choices': ['12 + 12 + 12', '10 + 10 + 16', '15 + 15 + 5', '18 + 18 + 2'],
            'correct': '12 + 12 + 12',
            'desc': 'Three 12s sum to 36.',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from bottom-left (0,0) to (3,2) in a 4x4 grid:',
            'choices': ['Up, Up, Right, Right, Right', 'Up, Up, Up, Right, Right', 'Right, Right, Up', 'Up, Up, Right'],
            'correct': 'Up, Up, Right, Right, Right',
            'desc': 'Move 3 steps Right and 2 steps Up to reach (3,2). (Note coordinate order).',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from (1,0) to (2,3) in a 4x4 grid:',
            'choices': ['Up, Up, Up, Right', 'Up, Up, Right, Right', 'Right, Up, Up', 'Up, Right, Right'],
            'correct': 'Up, Up, Up, Right',
            'desc': 'Move 1 step Right and 3 steps Up to go from (1,0) to (2,3).',
          },
          {
            'type': 'spatial',
            'question': 'Pattern Completion: What is next? A1, B2, C3, [?]',
            'choices': ['D3', 'D4', 'E4', 'E5'],
            'correct': 'D4',
            'desc': 'Letters increase by 1, numbers increase by 1.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 8.',
            'input': 8,
            'flow': 'true',
            'choices': ['6', '8', '10', '12'],
            'correct': '6',
            'desc': '8 + 4 = 12. 12 / 2 = 6. Since 6 > 5, output is 6.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 10.',
            'input': 10,
            'flow': 'true',
            'choices': ['5', '7', '9', '11'],
            'correct': '7',
            'desc': '10 + 4 = 14. 14 / 2 = 7. Since 7 > 5, output is 7.',
          }
        ];
        break;
      case 10:
        baseLevels = [
          {
            'type': 'spatial',
            'question': 'Cognitive Pattern: Grid [▲, ●] rotates 90° clockwise to become [?, ▲]. What is \'?\'?',
            'choices': ['●', '■', '◆', '▲'],
            'correct': '●',
            'desc': 'Rotating 90° moves top-right ● to top-left position.',
          },
          {
            'type': 'spatial',
            'question': 'Grid Rotation: [■, ★] rotates 180° to become:',
            'choices': ['[★, ■]', '[■, ★]', '[▲, ●]', '[★, ▲]'],
            'correct': '[★, ■]',
            'desc': '180° rotation swaps the left and right positions.',
          },
          {
            'type': 'spatial',
            'question': 'Number Series: What is next? 100, 90, 81, 73, [?]',
            'choices': ['65', '66', '67', '68'],
            'correct': '66',
            'desc': 'Subtract 10, then 9, then 8, then 7. 73 - 7 = 66.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 100:',
            'choices': ['40 + 40 + 20', '50 + 40 + 5', '60 + 30 + 5', '70 + 20 + 5'],
            'correct': '40 + 40 + 20',
            'desc': 'Addition: 40 + 40 + 20 = 100.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 45:',
            'choices': ['15 + 15 + 15', '20 + 20 + 10', '30 + 10 + 10', '25 + 15 + 10'],
            'correct': '15 + 15 + 15',
            'desc': 'Three 15s sum to 45.',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from bottom-left (0,0) to top-right (3,3) in a 4x4 grid:',
            'choices': ['Up, Up, Up, Right, Right, Right', 'Up, Right, Up, Right, Up, Right', 'Right, Right, Right, Up, Up, Up', 'All of the above'],
            'correct': 'All of the above',
            'desc': 'All paths correctly move 3 steps Up and 3 steps Right to reach (3,3).',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot backwards from (2,2) to (0,0):',
            'choices': ['Down, Down, Left, Left', 'Up, Up, Right, Right', 'Down, Left, Down', 'Left, Down, Left'],
            'correct': 'Down, Down, Left, Left',
            'desc': 'Move 2 steps Down and 2 steps Left to return to (0,0).',
          },
          {
            'type': 'spatial',
            'question': 'How many faces does a standard regular dodecahedron have?',
            'choices': ['6', '12', '20', '30'],
            'correct': '12',
            'desc': 'A dodecahedron has 12 pentagonal faces.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 12.',
            'input': 12,
            'flow': 'true',
            'choices': ['6', '8', '10', '12'],
            'correct': '8',
            'desc': '12 + 4 = 16. 16 / 2 = 8. Since 8 > 5, output is 8.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 2.',
            'input': 2,
            'flow': 'true',
            'choices': ['4', '6', '8', '10'],
            'correct': '6',
            'desc': '2 + 4 = 6. 6 / 2 = 3. Since 3 <= 5, output is 3 * 2 = 6.',
          }
        ];
        break;
      case 11:
        baseLevels = [
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate final output for Input = 12.',
            'input': 12,
            'flow': '[Input: 12] ➔ [+4] ➔ [/2] ➔ [If > 5: Output, Else: Output * 2]',
            'choices': ['6', '8', '10', '12'],
            'correct': '8',
            'desc': 'Logic Flow. 12 + 4 = 16. 16 / 2 = 8. Since 8 > 5, output is 8.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate final output for Input = 4.',
            'input': 4,
            'flow': 'true',
            'choices': ['4', '6', '8', '10'],
            'correct': '8',
            'desc': '4 + 4 = 8. 8 / 2 = 4. Since 4 <= 5, output is 4 * 2 = 8.',
          },
          {
            'type': 'spatial',
            'question': 'What is the dot product of vectors [1, 2] and [3, 4]?',
            'choices': ['10', '11', '14', '15'],
            'correct': '11',
            'desc': '1*3 + 2*4 = 3 + 8 = 11.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 80:',
            'choices': ['30 + 30 + 20', '40 + 30 + 5', '25 + 25 + 25', '50 + 20 + 5'],
            'correct': '30 + 30 + 20',
            'desc': 'Addition: 30 + 30 + 20 = 80.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 75:',
            'choices': ['25 + 25 + 25', '30 + 30 + 10', '40 + 20 + 10', '50 + 20 + 5'],
            'correct': '25 + 25 + 25',
            'desc': 'Three 25s sum to 75.',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from bottom-left (0,0) to (3,1) in a 4x4 grid:',
            'choices': ['Up, Up, Up, Right', 'Up, Up, Right, Right', 'Right, Right, Right, Up', 'Right, Up, Up'],
            'correct': 'Right, Right, Right, Up',
            'desc': 'Move 3 steps Right and 1 step Up to reach (3,1).',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from (1,1) to (3,0) in a 4x4 grid:',
            'choices': ['Up, Up, Left', 'Down, Right, Right', 'Down, Left, Left', 'Right, Right, Down'],
            'correct': 'Right, Right, Down',
            'desc': 'Move 2 steps Right and 1 step Down to reach (3,0).',
          },
          {
            'type': 'spatial',
            'question': 'Number Series: What is next? 1, 8, 27, 64, [?]',
            'choices': ['81', '100', '125', '216'],
            'correct': '125',
            'desc': 'Perfect cubes: 1³, 2³, 3³, 4³, 5³ = 125.',
          },
          {
            'type': 'spatial',
            'question': 'What is the determinant of the 2x2 matrix [1, 2; 3, 4]?',
            'choices': ['-2', '2', '-1', '0'],
            'correct': '-2',
            'desc': 'Determinant = (1*4) - (2*3) = 4 - 6 = -2.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 16.',
            'input': 16,
            'flow': 'true',
            'choices': ['8', '10', '12', '14'],
            'correct': '10',
            'desc': '16 + 4 = 20. 20 / 2 = 10. Since 10 > 5, output is 10.',
          }
        ];
        break;
      case 12:
      default:
        baseLevels = [
          {
            'type': 'flow',
            'question': 'Advanced Flow: Calculate final output for Input = 5.',
            'input': 5,
            'flow': '[Input: 5] ➔ [*3] ➔ [-5] ➔ [If even: Output / 2, Else: Output + 1]',
            'choices': ['5', '6', '10', '11'],
            'correct': '5',
            'desc': 'Advanced Flow. 5 * 3 = 15. 15 - 5 = 10. Since 10 is even, 10 / 2 = 5.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate final output for Input = 6.',
            'input': 6,
            'flow': 'true',
            'choices': ['5', '8', '10', '12'],
            'correct': '10',
            'desc': '6 + 4 = 10. 10 / 2 = 5. Since 5 <= 5, output is 5 * 2 = 10.',
          },
          {
            'type': 'spatial',
            'question': 'Number Series: What is next? 0, 1, 3, 6, 10, 15, [?]',
            'choices': ['20', '21', '22', '25'],
            'correct': '21',
            'desc': 'Add 1, then 2, then 3, then 4, etc. 15 + 6 = 21.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 150:',
            'choices': ['50 + 50 + 50', '60 + 60 + 30', '70 + 70 + 10', '80 + 40 + 30'],
            'correct': '50 + 50 + 50',
            'desc': 'Three 50s sum to 150.',
          },
          {
            'type': 'bubbles',
            'question': 'Target Math: Select the bubble formula that sums to exactly 99:',
            'choices': ['33 + 33 + 33', '30 + 30 + 39', '40 + 40 + 19', '50 + 40 + 9'],
            'correct': '33 + 33 + 33',
            'desc': 'Three 33s sum to 99.',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from bottom-left (0,0) to top-right (3,3) in a 4x4 grid:',
            'choices': ['Up, Up, Up, Right, Right, Right', 'Up, Right, Up, Right, Up, Right', 'Right, Right, Right, Up, Up, Up', 'All of the above'],
            'correct': 'All of the above',
            'desc': 'All paths correctly move 3 steps Up and 3 steps Right to reach (3,3).',
          },
          {
            'type': 'pathfinder',
            'question': 'Grid Pathfinder: Move robot from (1,2) to (3,1) in a 4x4 grid:',
            'choices': ['Right, Right, Down', 'Up, Up, Left', 'Right, Down, Right', 'Down, Down, Right'],
            'correct': 'Right, Right, Down',
            'desc': 'Move 2 steps Right and 1 step Down to reach (3,1) from (1,2).',
          },
          {
            'type': 'spatial',
            'question': 'Binary Addition: Calculate the sum of binary numbers 1010 + 0101:',
            'choices': ['1010', '1111', '10000', '1100'],
            'correct': '1111',
            'desc': 'Binary: 1010 (10) + 0101 (5) = 1111 (15).',
          },
          {
            'type': 'spatial',
            'question': 'What is the determinant of the diagonal 2x2 matrix [2, 0; 0, 3]?',
            'choices': ['5', '6', '0', '1'],
            'correct': '6',
            'desc': 'Determinant = 2*3 - 0*0 = 6.',
          },
          {
            'type': 'flow',
            'question': 'Flow Processor: Calculate output for Input = 10.',
            'input': 10,
            'flow': 'true',
            'choices': ['5', '7', '9', '11'],
            'correct': '7',
            'desc': '10 + 4 = 14. 14 / 2 = 7. Since 7 > 5, output is 7.',
          }
        ];
        break;
    }

    final state = Provider.of<AppState>(context, listen: false);
    final customLevels = state.customCognitiveLevels
        .where((lvl) => lvl['class'] == _selectedClass)
        .map((lvl) {
          final mappedType = lvl['type'] == 'Spatial Match' ? 'spatial' : 'pathfinder';
          return {
            'type': mappedType,
            'question': lvl['question'],
            'original': lvl['original'],
            'choices': List<String>.from(lvl['choices']),
            'correct': lvl['correct'],
            'desc': lvl['desc'],
          };
        }).toList();

    return [...baseLevels, ...customLevels];
  }

  List<Map<String, dynamic>> _getSyntaxLevels() {
    final List<Map<String, dynamic>> baseLevels;
    int classNum = int.tryParse(_selectedClass.replaceAll('Class ', '')) ?? 1;
    switch (classNum) {
      case 1:
        baseLevels = [
          {
            'desc': 'Assemble Scratch blocks to move forward:',
            'tiles': ['[Move]', '[Start]', '[End]'],
            'correct': ['[Start]', '[Move]', '[End]'],
          },
          {
            'desc': 'Assemble Scratch blocks to turn left:',
            'tiles': ['[Turn]', '[Start]', '[End]'],
            'correct': ['[Start]', '[Turn]', '[End]'],
          },
          {
            'desc': 'Assemble Scratch blocks to jump high:',
            'tiles': ['[Jump]', '[Start]', '[End]'],
            'correct': ['[Start]', '[Jump]', '[End]'],
          },
          {
            'desc': 'Assemble Scratch blocks to move and jump:',
            'tiles': ['[Jump]', '[Start]', '[Move]', '[End]'],
            'correct': ['[Start]', '[Move]', '[Jump]', '[End]'],
          },
          {
            'desc': 'Assemble Scratch blocks to jump & turn:',
            'tiles': ['[Start]', '[Jump]', '[Turn]', '[End]'],
            'correct': ['[Start]', '[Jump]', '[Turn]', '[End]'],
          },
          {
            'desc': 'Assemble Scratch blocks to move and turn:',
            'tiles': ['[Move]', '[Start]', '[Turn]', '[End]'],
            'correct': ['[Start]', '[Move]', '[Turn]', '[End]'],
          },
          {
            'desc': 'Assemble Scratch blocks to double move:',
            'tiles': ['[Move]', '[Start]', '[Move]', '[End]'],
            'correct': ['[Start]', '[Move]', '[Move]', '[End]'],
          },
          {
            'desc': 'Assemble Scratch blocks to turn and move:',
            'tiles': ['[Turn]', '[Start]', '[Move]', '[End]'],
            'correct': ['[Start]', '[Turn]', '[Move]', '[End]'],
          },
          {
            'desc': 'Assemble Scratch blocks to double jump:',
            'tiles': ['[Jump]', '[Start]', '[Jump]', '[End]'],
            'correct': ['[Start]', '[Jump]', '[Jump]', '[End]'],
          },
          {
            'desc': 'Assemble Scratch blocks to move, jump, and turn:',
            'tiles': ['[Turn]', '[Jump]', '[Start]', '[Move]', '[End]'],
            'correct': ['[Start]', '[Move]', '[Jump]', '[Turn]', '[End]'],
          }
        ];
        break;
      case 2:
        baseLevels = [
          {
            'desc': 'Assemble Scratch blocks to jump & turn:',
            'tiles': ['[Start]', '[Jump]', '[Turn]', '[End]'],
            'correct': ['[Start]', '[Jump]', '[Turn]', '[End]'],
          },
          {
            'desc': 'Assemble blocks to start and jump:',
            'tiles': ['[Jump]', '[Start]', '[End]'],
            'correct': ['[Start]', '[Jump]', '[End]'],
          },
          {
            'desc': 'Assemble blocks to move twice:',
            'tiles': ['[Move]', '[Start]', '[Move]', '[End]'],
            'correct': ['[Start]', '[Move]', '[Move]', '[End]'],
          },
          {
            'desc': 'Assemble blocks to move, turn, and move:',
            'tiles': ['[Move]', '[Start]', '[Turn]', '[Move]', '[End]'],
            'correct': ['[Start]', '[Move]', '[Turn]', '[Move]', '[End]'],
          },
          {
            'desc': 'Assemble blocks to repeat jump:',
            'tiles': ['[Repeat]', '[Start]', '[Jump]', '[End]'],
            'correct': ['[Start]', '[Repeat]', '[Jump]', '[End]'],
          },
          {
            'desc': 'Assemble blocks to repeat move:',
            'tiles': ['[Repeat]', '[Start]', '[Move]', '[End]'],
            'correct': ['[Start]', '[Repeat]', '[Move]', '[End]'],
          },
          {
            'desc': 'Assemble blocks to repeat turn:',
            'tiles': ['[Repeat]', '[Start]', '[Turn]', '[End]'],
            'correct': ['[Start]', '[Repeat]', '[Turn]', '[End]'],
          },
          {
            'desc': 'Assemble blocks to check color sensor:',
            'tiles': ['[If Red]', '[Start]', '[Stop]', '[End]'],
            'correct': ['[Start]', '[If Red]', '[Stop]', '[End]'],
          },
          {
            'desc': 'Assemble blocks to wait and move:',
            'tiles': ['[Wait]', '[Start]', '[Move]', '[End]'],
            'correct': ['[Start]', '[Wait]', '[Move]', '[End]'],
          },
          {
            'desc': 'Assemble blocks to wait and turn:',
            'tiles': ['[Wait]', '[Start]', '[Turn]', '[End]'],
            'correct': ['[Start]', '[Wait]', '[Turn]', '[End]'],
          }
        ];
        break;
      case 3:
        baseLevels = [
          {
            'desc': 'Order basic commands to print two messages:',
            'tiles': ['print("Hello")', 'print("World")', 'print("End")'],
            'correct': ['print("Hello")', 'print("World")', 'print("End")'],
          },
          {
            'desc': 'Assemble statements to print a greeting:',
            'tiles': ['print("Hi")', 'print("There")'],
            'correct': ['print("Hi")', 'print("There")'],
          },
          {
            'desc': 'Assemble statements to print numbers:',
            'tiles': ['print(1)', 'print(2)', 'print(3)'],
            'correct': ['print(1)', 'print(2)', 'print(3)'],
          },
          {
            'desc': 'Assemble print statement syntax:',
            'tiles': ['print', '("Hi")', ';'],
            'correct': ['print', '("Hi")', ';'],
          },
          {
            'desc': 'Assemble statements to print start and stop:',
            'tiles': ['print("Start")', 'print("Stop")'],
            'correct': ['print("Start")', 'print("Stop")'],
          },
          {
            'desc': 'Assemble statements to print calculation:',
            'tiles': ['print', '(5 + 5)'],
            'correct': ['print', '(5 + 5)'],
          },
          {
            'desc': 'Assemble statements to print comparison:',
            'tiles': ['print', '(10 > 5)'],
            'correct': ['print', '(10 > 5)'],
          },
          {
            'desc': 'Assemble statements to print logic:',
            'tiles': ['print', '(True)'],
            'correct': ['print', '(True)'],
          },
          {
            'desc': 'Assemble code to declare comments:',
            'tiles': ['# Comment', 'print("Run")'],
            'correct': ['# Comment', 'print("Run")'],
          },
          {
            'desc': 'Assemble statements to print variable name:',
            'tiles': ['print', '("Name")'],
            'correct': ['print', '("Name")'],
          }
        ];
        break;
      case 4:
        baseLevels = [
          {
            'desc': 'Assemble HTML blocks to output a paragraph:',
            'tiles': ['<p>', 'Hello World', '</p>'],
            'correct': ['<p>', 'Hello World', '</p>'],
          },
          {
            'desc': 'Assemble HTML blocks to output a heading:',
            'tiles': ['My Heading', '<h1>', '</h1>'],
            'correct': ['<h1>', 'My Heading', '</h1>'],
          },
          {
            'desc': 'Assemble HTML blocks for bold text:',
            'tiles': ['Bold Text', '<b>', '</b>'],
            'correct': ['<b>', 'Bold Text', '</b>'],
          },
          {
            'desc': 'Assemble HTML blocks for italic text:',
            'tiles': ['Italic Text', '<i>', '</i>'],
            'correct': ['<i>', 'Italic Text', '</i>'],
          },
          {
            'desc': 'Assemble HTML blocks for an anchor link:',
            'tiles': ['Link', '<a>', '</a>'],
            'correct': ['<a>', 'Link', '</a>'],
          },
          {
            'desc': 'Assemble HTML blocks for a title tag:',
            'tiles': ['Title Here', '<title>', '</title>'],
            'correct': ['<title>', 'Title Here', '</title>'],
          },
          {
            'desc': 'Assemble HTML blocks for division wrapper:',
            'tiles': ['Content', '<div>', '</div>'],
            'correct': ['<div>', 'Content', '</div>'],
          },
          {
            'desc': 'Assemble HTML blocks for list item:',
            'tiles': ['Item 1', '<li>', '</li>'],
            'correct': ['<li>', 'Item 1', '</li>'],
          },
          {
            'desc': 'Assemble HTML blocks for image placeholder:',
            'tiles': ['src="img.png"', '<img', '/>'],
            'correct': ['<img', 'src="img.png"', '/>'],
          },
          {
            'desc': 'Assemble HTML blocks for page section:',
            'tiles': ['Section Content', '<section>', '</section>'],
            'correct': ['<section>', 'Section Content', '</section>'],
          }
        ];
        break;
      case 5:
        baseLevels = [
          {
            'desc': 'Assemble HTML blocks to output a heading inside body:',
            'tiles': ['<body>', '<h1>Hi</h1>', '</body>'],
            'correct': ['<body>', '<h1>Hi</h1>', '</body>'],
          },
          {
            'desc': 'Assemble HTML blocks to output a paragraph inside body:',
            'tiles': ['<p>Text</p>', '<body>', '</body>'],
            'correct': ['<body>', '<p>Text</p>', '</body>'],
          },
          {
            'desc': 'Assemble HTML header blocks:',
            'tiles': ['<title>Home</title>', '<head>', '</head>'],
            'correct': ['<head>', '<title>Home</title>', '</head>'],
          },
          {
            'desc': 'Assemble HTML list container:',
            'tiles': ['<li>Item</li>', '<ul>', '</ul>'],
            'correct': ['<ul>', '<li>Item</li>', '</ul>'],
          },
          {
            'desc': 'Assemble HTML ordered list container:',
            'tiles': ['<li>Step 1</li>', '<ol>', '</ol>'],
            'correct': ['<ol>', '<li>Step 1</li>', '</ol>'],
          },
          {
            'desc': 'Assemble HTML table row:',
            'tiles': ['<td>Data</td>', '<tr>', '</tr>'],
            'correct': ['<tr>', '<td>Data</td>', '</tr>'],
          },
          {
            'desc': 'Assemble HTML table body container:',
            'tiles': ['<tr>Row</tr>', '<tbody>', '</tbody>'],
            'correct': ['<tbody>', '<tr>Row</tr>', '</tbody>'],
          },
          {
            'desc': 'Assemble HTML link reference tag:',
            'tiles': ['href="style.css"', '<link rel="stylesheet"', '/>'],
            'correct': ['<link rel="stylesheet"', 'href="style.css"', '/>'],
          },
          {
            'desc': 'Assemble HTML button container:',
            'tiles': ['Click Me', '<button>', '</button>'],
            'correct': ['<button>', 'Click Me', '</button>'],
          },
          {
            'desc': 'Assemble HTML blockquote quote:',
            'tiles': ['"To be or not to be"', '<blockquote>', '</blockquote>'],
            'correct': ['<blockquote>', '"To be or not to be"', '</blockquote>'],
          }
        ];
        break;
      case 6:
        baseLevels = [
          {
            'desc': 'Assemble HTML blocks to output a standard HTML page:',
            'tiles': ['<html>', '<body>', '<h1>Hi</h1>', '</body>', '</html>'],
            'correct': ['<html>', '<body>', '<h1>Hi</h1>', '</body>', '</html>'],
          },
          {
            'desc': 'Assemble HTML page with head and body:',
            'tiles': ['<html>', '<head></head>', '<body></body>', '</html>'],
            'correct': ['<html>', '<head></head>', '<body></body>', '</html>'],
          },
          {
            'desc': 'Assemble HTML meta description tag:',
            'tiles': ['name="description"', '<meta', 'content="Info"', '/>'],
            'correct': ['<meta', 'name="description"', 'content="Info"', '/>'],
          },
          {
            'desc': 'Assemble HTML form element:',
            'tiles': ['<form>', '<input type="text" />', '</form>'],
            'correct': ['<form>', '<input type="text" />', '</form>'],
          },
          {
            'desc': 'Assemble HTML block for scripting:',
            'tiles': ['<script>', 'console.log("Hi");', '</script>'],
            'correct': ['<script>', 'console.log("Hi");', '</script>'],
          },
          {
            'desc': 'Assemble HTML style rules wrapper:',
            'tiles': ['<style>', 'h1 { color: red; }', '</style>'],
            'correct': ['<style>', 'h1 { color: red; }', '</style>'],
          },
          {
            'desc': 'Assemble CSS rule block for body color:',
            'tiles': ['body {', 'background-color: blue;', '}'],
            'correct': ['body {', 'background-color: blue;', '}'],
          },
          {
            'desc': 'Assemble CSS rule block for text centering:',
            'tiles': ['p {', 'text-align: center;', '}'],
            'correct': ['p {', 'text-align: center;', '}'],
          },
          {
            'desc': 'Assemble CSS rule block for font sizing:',
            'tiles': ['span {', 'font-size: 16px;', '}'],
            'correct': ['span {', 'font-size: 16px;', '}'],
          },
          {
            'desc': 'Assemble CSS rule block for margin padding reset:',
            'tiles': ['* {', 'margin: 0;', 'padding: 0;', '}'],
            'correct': ['* {', 'margin: 0;', 'padding: 0;', '}'],
          }
        ];
        break;
      case 7:
        baseLevels = [
          {
            'desc': 'Assemble Python code to assign x = 100:',
            'tiles': ['x', '=', '100'],
            'correct': ['x', '=', '100'],
          },
          {
            'desc': 'Assemble Python code to assign name = "Alice":',
            'tiles': ['name', '=', '"Alice"'],
            'correct': ['name', '=', '"Alice"'],
          },
          {
            'desc': 'Assemble Python code to assign boolean flag = True:',
            'tiles': ['flag', '=', 'True'],
            'correct': ['flag', '=', 'True'],
          },
          {
            'desc': 'Assemble Python code to calculate sum z = x + y:',
            'tiles': ['z', '=', 'x + y'],
            'correct': ['z', '=', 'x + y'],
          },
          {
            'desc': 'Assemble Python code to calculate product product = a * b:',
            'tiles': ['product', '=', 'a * b'],
            'correct': ['product', '=', 'a * b'],
          },
          {
            'desc': 'Assemble Python code to update counter count += 1:',
            'tiles': ['count', '+=', '1'],
            'correct': ['count', '+=', '1'],
          },
          {
            'desc': 'Assemble Python code to calculate ratio ratio = total / 2:',
            'tiles': ['ratio', '=', 'total / 2'],
            'correct': ['ratio', '=', 'total / 2'],
          },
          {
            'desc': 'Assemble Python code to check division remainder mod = value % 2:',
            'tiles': ['mod', '=', 'value % 2'],
            'correct': ['mod', '=', 'value % 2'],
          },
          {
            'desc': 'Assemble Python code to assign multiple a, b = 1, 2:',
            'tiles': ['a, b', '=', '1, 2'],
            'correct': ['a, b', '=', '1, 2'],
          },
          {
            'desc': 'Assemble Python code to perform floor division val = 7 // 2:',
            'tiles': ['val', '=', '7 // 2'],
            'correct': ['val', '=', '7 // 2'],
          }
        ];
        break;
      case 8:
        baseLevels = [
          {
            'desc': 'Assemble Python code to print a variable:',
            'tiles': ['name = "Adyapan"', 'print(name)'],
            'correct': ['name = "Adyapan"', 'print(name)'],
          },
          {
            'desc': 'Assemble Python code to input and print:',
            'tiles': ['x = input("Enter:")', 'print(x)'],
            'correct': ['x = input("Enter:")', 'print(x)'],
          },
          {
            'desc': 'Assemble Python code to cast float to int:',
            'tiles': ['x = 5.5', 'y = int(x)', 'print(y)'],
            'correct': ['x = 5.5', 'y = int(x)', 'print(y)'],
          },
          {
            'desc': 'Assemble Python code to cast string to float:',
            'tiles': ['s = "3.14"', 'f = float(s)', 'print(f)'],
            'correct': ['s = "3.14"', 'f = float(s)', 'print(f)'],
          },
          {
            'desc': 'Assemble Python code to print formatted string:',
            'tiles': ['age = 15', 'print(f"Age: {age}")'],
            'correct': ['age = 15', 'print(f"Age: {age}")'],
          },
          {
            'desc': 'Assemble Python code to print multiple arguments:',
            'tiles': ['print("Sum is:", 10)'],
            'correct': ['print("Sum is:", 10)'],
          },
          {
            'desc': 'Assemble Python code to print with custom separator:',
            'tiles': ['print("A", "B", sep="-")'],
            'correct': ['print("A", "B", sep="-")'],
          },
          {
            'desc': 'Assemble Python code to print with end parameter:',
            'tiles': ['print("Hello", end=" ")', 'print("World")'],
            'correct': ['print("Hello", end=" ")', 'print("World")'],
          },
          {
            'desc': 'Assemble Python code to import math and print pi:',
            'tiles': ['import math', 'print(math.pi)'],
            'correct': ['import math', 'print(math.pi)'],
          },
          {
            'desc': 'Assemble Python code to import random and print integer:',
            'tiles': ['import random', 'print(random.randint(1, 10))'],
            'correct': ['import random', 'print(random.randint(1, 10))'],
          }
        ];
        break;
      case 9:
        baseLevels = [
          {
            'desc': 'Assemble Python code to assign and print sum:',
            'tiles': ['x = 5', 'y = 10', 'print(x + y)'],
            'correct': ['x = 5', 'y = 10', 'print(x + y)'],
          },
          {
            'desc': 'Assemble Python code to compare two variables:',
            'tiles': ['a = 15', 'b = 20', 'print(a < b)'],
            'correct': ['a = 15', 'b = 20', 'print(a < b)'],
          },
          {
            'desc': 'Assemble Python code to check logical AND condition:',
            'tiles': ['x = True', 'y = False', 'print(x and y)'],
            'correct': ['x = True', 'y = False', 'print(x and y)'],
          },
          {
            'desc': 'Assemble Python code to check logical OR condition:',
            'tiles': ['x = True', 'y = False', 'print(x or y)'],
            'correct': ['x = True', 'y = False', 'print(x or y)'],
          },
          {
            'desc': 'Assemble Python code to negate logic:',
            'tiles': ['flag = False', 'print(not flag)'],
            'correct': ['flag = False', 'print(not flag)'],
          },
          {
            'desc': 'Assemble Python code to print string length:',
            'tiles': ['msg = "Code"', 'print(len(msg))'],
            'correct': ['msg = "Code"', 'print(len(msg))'],
          },
          {
            'desc': 'Assemble Python code to concatenate strings:',
            'tiles': ['s1 = "A"', 's2 = "B"', 'print(s1 + s2)'],
            'correct': ['s1 = "A"', 's2 = "B"', 'print(s1 + s2)'],
          },
          {
            'desc': 'Assemble Python code to repeat string:',
            'tiles': ['s = "Ho"', 'print(s * 3)'],
            'correct': ['s = "Ho"', 'print(s * 3)'],
          },
          {
            'desc': 'Assemble Python code to print list element:',
            'tiles': ['items = [1, 2]', 'print(items[0])'],
            'correct': ['items = [1, 2]', 'print(items[0])'],
          },
          {
            'desc': 'Assemble Python code to check membership:',
            'tiles': ['nums = [1, 2, 3]', 'print(2 in nums)'],
            'correct': ['nums = [1, 2, 3]', 'print(2 in nums)'],
          }
        ];
        break;
      case 10:
        baseLevels = [
          {
            'desc': 'Assemble Python code to print numbers 0 to 2 using loop:',
            'tiles': ['for i in range(3):', 'print(i)'],
            'correct': ['for i in range(3):', 'print(i)'],
          },
          {
            'desc': 'Assemble Python code to double loop print coordinates:',
            'tiles': ['for x in range(2):', 'for y in range(2):', 'print(x, y)'],
            'correct': ['for x in range(2):', 'for y in range(2):', 'print(x, y)'],
          },
          {
            'desc': 'Assemble Python code to loop over list elements:',
            'tiles': ['fruits = ["apple", "banana"]', 'for fruit in fruits:', 'print(fruit)'],
            'correct': ['fruits = ["apple", "banana"]', 'for fruit in fruits:', 'print(fruit)'],
          },
          {
            'desc': 'Assemble Python code to loop with step index:',
            'tiles': ['for i in range(0, 6, 2):', 'print(i)'],
            'correct': ['for i in range(0, 6, 2):', 'print(i)'],
          },
          {
            'desc': 'Assemble Python code to loop backward:',
            'tiles': ['for i in range(3, 0, -1):', 'print(i)'],
            'correct': ['for i in range(3, 0, -1):', 'print(i)'],
          },
          {
            'desc': 'Assemble Python code for while loop counter:',
            'tiles': ['i = 0', 'while i < 3:', 'print(i)', 'i += 1'],
            'correct': ['i = 0', 'while i < 3:', 'print(i)', 'i += 1'],
          },
          {
            'desc': 'Assemble Python code for infinite while loop with break:',
            'tiles': ['while True:', 'print("Run")', 'break'],
            'correct': ['while True:', 'print("Run")', 'break'],
          },
          {
            'desc': 'Assemble Python code to skip iteration using continue:',
            'tiles': ['for i in range(3):', 'if i == 1:', 'continue', 'print(i)'],
            'correct': ['for i in range(3):', 'if i == 1:', 'continue', 'print(i)'],
          },
          {
            'desc': 'Assemble Python code to print indices with enumerate:',
            'tiles': ['names = ["A", "B"]', 'for idx, val in enumerate(names):', 'print(idx, val)'],
            'correct': ['names = ["A", "B"]', 'for idx, val in enumerate(names):', 'print(idx, val)'],
          },
          {
            'desc': 'Assemble Python code to loop over dictionary keys/values:',
            'tiles': ['d = {"a": 1}', 'for k, v in d.items():', 'print(k, v)'],
            'correct': ['d = {"a": 1}', 'for k, v in d.items():', 'print(k, v)'],
          }
        ];
        break;
      case 11:
        baseLevels = [
          {
            'desc': 'Create an If statement checking if score > 50:',
            'tiles': ['if score > 50:', 'print("Pass")', 'else:', 'print("Fail")'],
            'correct': ['if score > 50:', 'print("Pass")', 'else:', 'print("Fail")'],
          },
          {
            'desc': 'Create If-Elif-Else block checking number sign:',
            'tiles': ['if x > 0:', 'print("Positive")', 'elif x < 0:', 'print("Negative")', 'else:', 'print("Zero")'],
            'correct': ['if x > 0:', 'print("Positive")', 'elif x < 0:', 'print("Negative")', 'else:', 'print("Zero")'],
          },
          {
            'desc': 'Create If statement checking even/odd:',
            'tiles': ['if num % 2 == 0:', 'print("Even")', 'else:', 'print("Odd")'],
            'correct': ['if num % 2 == 0:', 'print("Even")', 'else:', 'print("Odd")'],
          },
          {
            'desc': 'Create If block with logical operators:',
            'tiles': ['if x > 0 and y > 0:', 'print("Quadrant 1")'],
            'correct': ['if x > 0 and y > 0:', 'print("Quadrant 1")'],
          },
          {
            'desc': 'Create nested If statement checks:',
            'tiles': ['if age >= 18:', 'if has_id:', 'print("Allow")'],
            'correct': ['if age >= 18:', 'if has_id:', 'print("Allow")'],
          },
          {
            'desc': 'Create conditional expression (ternary operator):',
            'tiles': ['status = "Adult"', 'if age >= 18', 'else "Minor"'],
            'correct': ['status = "Adult"', 'if age >= 18', 'else "Minor"'],
          },
          {
            'desc': 'Create If statement checking empty list:',
            'tiles': ['items = []', 'if not items:', 'print("Empty")'],
            'correct': ['items = []', 'if not items:', 'print("Empty")'],
          },
          {
            'desc': 'Create If statement checking string prefix:',
            'tiles': ['name = "Admin"', 'if name.startswith("Ad"):', 'print("Match")'],
            'correct': ['name = "Admin"', 'if name.startswith("Ad"):', 'print("Match")'],
          },
          {
            'desc': 'Create If checking type match:',
            'tiles': ['x = 10', 'if isinstance(x, int):', 'print("Integer")'],
            'correct': ['x = 10', 'if isinstance(x, int):', 'print("Integer")'],
          },
          {
            'desc': 'Create If checking dictionary key existence:',
            'tiles': ['data = {"id": 1}', 'if "id" in data:', 'print("Found")'],
            'correct': ['data = {"id": 1}', 'if "id" in data:', 'print("Found")'],
          }
        ];
        break;
      case 12:
      default:
        baseLevels = [
          {
            'desc': 'Assemble Python code to print "Hello World" inside function:',
            'tiles': ['def main():', 'print', '("Hello World")', ';'],
            'correct': ['def main():', 'print', '("Hello World")', ';'],
          },
          {
            'desc': 'Assemble function returning square of x:',
            'tiles': ['def square(x):', 'return x * x'],
            'correct': ['def square(x):', 'return x * x'],
          },
          {
            'desc': 'Assemble function calculating rectangle area with default parameters:',
            'tiles': ['def area(w, h=10):', 'return w * h'],
            'correct': ['def area(w, h=10):', 'return w * h'],
          },
          {
            'desc': 'Assemble function taking variable keyword arguments:',
            'tiles': ['def print_data(**kwargs):', 'for k, v in kwargs.items():', 'print(k, v)'],
            'correct': ['def print_data(**kwargs):', 'for k, v in kwargs.items():', 'print(k, v)'],
          },
          {
            'desc': 'Assemble lambda expression squaring value:',
            'tiles': ['sq = lambda x:', 'x * x'],
            'correct': ['sq = lambda x:', 'x * x'],
          },
          {
            'desc': 'Assemble generator function yielding numbers:',
            'tiles': ['def gen():', 'yield 1', 'yield 2'],
            'correct': ['def gen():', 'yield 1', 'yield 2'],
          },
          {
            'desc': 'Assemble simple class declaration:',
            'tiles': ['class Student:', 'def __init__(self, name):', 'self.name = name'],
            'correct': ['class Student:', 'def __init__(self, name):', 'self.name = name'],
          },
          {
            'desc': 'Assemble class method inheritance call:',
            'tiles': ['class Dog(Animal):', 'def speak(self):', 'super().speak()'],
            'correct': ['class Dog(Animal):', 'def speak(self):', 'super().speak()'],
          },
          {
            'desc': 'Assemble try-except block handling ZeroDivisionError:',
            'tiles': ['try:', 'ans = 10 / 0', 'except ZeroDivisionError:', 'print("Error")'],
            'correct': ['try:', 'ans = 10 / 0', 'except ZeroDivisionError:', 'print("Error")'],
          },
          {
            'desc': 'Assemble code using "with" statement file open context:',
            'tiles': ['with open("file.txt") as f:', 'data = f.read()', 'print(data)'],
            'correct': ['with open("file.txt") as f:', 'data = f.read()', 'print(data)'],
          }
        ];
        break;
    }

    final state = Provider.of<AppState>(context, listen: false);
    final customLevels = state.customSyntaxLevels
        .where((lvl) => lvl['class'] == _selectedClass)
        .map((lvl) {
          return {
            'desc': lvl['desc'],
            'tiles': List<String>.from(lvl['tiles']),
            'correct': List<String>.from(lvl['correct']),
          };
        }).toList();

    return [...baseLevels, ...customLevels];
  }

  List<Map<String, dynamic>> _getUnscrambleLevels() {
    final List<Map<String, dynamic>> baseLevels;
    int classNum = int.tryParse(_selectedClass.replaceAll('Class ', '')) ?? 1;
    switch (classNum) {
      case 1:
        baseLevels = [
          {
            'word': 'SUN',
            'scrambled': ['U', 'N', 'S'],
            'category': '🌌 Science',
            'hint': 'The star at the center of our Solar System.',
          },
          {
            'word': 'CAT',
            'scrambled': ['A', 'T', 'C'],
            'category': '🐱 Animals',
            'hint': 'A popular furry pet that meows.',
          },
          {
            'word': 'DOG',
            'scrambled': ['G', 'O', 'D'],
            'category': '🐶 Animals',
            'hint': 'A loyal pet that barks.',
          },
          {
            'word': 'RED',
            'scrambled': ['E', 'D', 'R'],
            'category': '🎨 Colors',
            'hint': 'The color of an apple.',
          },
          {
            'word': 'BOX',
            'scrambled': ['X', 'O', 'B'],
            'category': '📦 Objects',
            'hint': 'A container to store things.',
          },
          {
            'word': 'PEN',
            'scrambled': ['N', 'E', 'P'],
            'category': '✏️ School',
            'hint': 'Used for writing on paper.',
          },
          {
            'word': 'TOY',
            'scrambled': ['Y', 'O', 'T'],
            'category': '🧸 Play',
            'hint': 'Something you play with.',
          },
          {
            'word': 'RUN',
            'scrambled': ['U', 'N', 'R'],
            'category': '🏃 Actions',
            'hint': 'To move fast on your feet.',
          },
          {
            'word': 'FLY',
            'scrambled': ['Y', 'L', 'F'],
            'category': '🐦 Actions',
            'hint': 'To move through the air.',
          },
          {
            'word': 'CUP',
            'scrambled': ['P', 'U', 'C'],
            'category': '🥛 Objects',
            'hint': 'Used for drinking tea or water.',
          }
        ];
        break;
      case 2:
        baseLevels = [
          {
            'word': 'STAR',
            'scrambled': ['A', 'R', 'T', 'S'],
            'category': '🌌 Astronomy',
            'hint': 'A glowing point of light in the night sky.',
          },
          {
            'word': 'MOON',
            'scrambled': ['O', 'O', 'N', 'M'],
            'category': '🌌 Astronomy',
            'hint': 'Earth\'s natural satellite.',
          },
          {
            'word': 'BIRD',
            'scrambled': ['R', 'I', 'B', 'D'],
            'category': '🐦 Animals',
            'hint': 'A feathered creature that flies.',
          },
          {
            'word': 'FISH',
            'scrambled': ['S', 'I', 'F', 'H'],
            'category': '🐟 Animals',
            'hint': 'A creature that swims in water.',
          },
          {
            'word': 'TREE',
            'scrambled': ['E', 'E', 'R', 'T'],
            'category': '🌿 Nature',
            'hint': 'A tall plant with a wooden trunk.',
          },
          {
            'word': 'BOOK',
            'scrambled': ['O', 'K', 'O', 'B'],
            'category': '📖 School',
            'hint': 'You read this to learn.',
          },
          {
            'word': 'HOME',
            'scrambled': ['M', 'O', 'H', 'E'],
            'category': '🏠 Places',
            'hint': 'The place where you live.',
          },
          {
            'word': 'ROAD',
            'scrambled': ['O', 'D', 'A', 'R'],
            'category': '🚗 Travel',
            'hint': 'Cars and buses drive on this.',
          },
          {
            'word': 'WIND',
            'scrambled': ['D', 'N', 'I', 'W'],
            'category': '💨 Weather',
            'hint': 'Moving air that blows leaves.',
          },
          {
            'word': 'RAIN',
            'scrambled': ['I', 'A', 'R', 'N'],
            'category': '💧 Weather',
            'hint': 'Water falling from clouds.',
          }
        ];
        break;
      case 3:
        baseLevels = [
          {
            'word': 'ATOM',
            'scrambled': ['O', 'T', 'M', 'A'],
            'category': '⚛️ Science',
            'hint': 'The basic building block of all matter.',
          },
          {
            'word': 'MATH',
            'scrambled': ['T', 'H', 'M', 'A'],
            'category': '📐 Math',
            'hint': 'Science of numbers and shapes.',
          },
          {
            'word': 'LIGHT',
            'scrambled': ['T', 'H', 'G', 'I', 'L'],
            'category': '💡 Physics',
            'hint': 'Allows us to see things.',
          },
          {
            'word': 'SOUND',
            'scrambled': ['D', 'N', 'U', 'O', 'S'],
            'category': '🔊 Physics',
            'hint': 'What you hear with your ears.',
          },
          {
            'word': 'FRUIT',
            'scrambled': ['T', 'I', 'U', 'R', 'F'],
            'category': '🍎 Food',
            'hint': 'A sweet plant product like an apple.',
          },
          {
            'word': 'SPACE',
            'scrambled': ['C', 'A', 'P', 'E', 'S'],
            'category': '🌌 Astronomy',
            'hint': 'The vast empty area outside Earth.',
          },
          {
            'word': 'CLOUD',
            'scrambled': ['D', 'U', 'O', 'L', 'C'],
            'category': '☁️ Weather',
            'hint': 'White fluffy mass in the sky.',
          },
          {
            'word': 'RIVER',
            'scrambled': ['R', 'E', 'V', 'I', 'R'],
            'category': '🏞️ Geography',
            'hint': 'Flowing body of fresh water.',
          },
          {
            'word': 'GLASS',
            'scrambled': ['S', 'S', 'A', 'L', 'G'],
            'category': '🧪 Materials',
            'hint': 'Transparent material used for windows.',
          },
          {
            'word': 'PLANT',
            'scrambled': ['T', 'N', 'A', 'P', 'L'],
            'category': '🌿 Nature',
            'hint': 'A green living thing in soil.',
          }
        ];
        break;
      case 4:
        baseLevels = [
          {
            'word': 'EARTH',
            'scrambled': ['H', 'T', 'R', 'A', 'E'],
            'category': '🌍 Science',
            'hint': 'Our home planet, third from the Sun.',
          },
          {
            'word': 'PLANT',
            'scrambled': ['T', 'N', 'A', 'P', 'L'],
            'category': '🌿 Biology',
            'hint': 'Living organism that performs photosynthesis.',
          },
          {
            'word': 'GRASS',
            'scrambled': ['S', 'S', 'A', 'R', 'G'],
            'category': '🌿 Nature',
            'hint': 'Green ground cover.',
          },
          {
            'word': 'SOLID',
            'scrambled': ['D', 'I', 'L', 'O', 'S'],
            'category': '🧪 Physics',
            'hint': 'State of matter that holds its shape.',
          },
          {
            'word': 'METAL',
            'scrambled': ['L', 'A', 'T', 'E', 'M'],
            'category': '🔩 Materials',
            'hint': 'Shiny, hard element like iron.',
          },
          {
            'word': 'WATER',
            'scrambled': ['R', 'E', 'T', 'A', 'W'],
            'category': '💧 Nature',
            'hint': 'Liquid essential for all life.',
          },
          {
            'word': 'OCEAN',
            'scrambled': ['N', 'A', 'E', 'C', 'O'],
            'category': '🌊 Geography',
            'hint': 'Large body of salty water.',
          },
          {
            'word': 'SOLAR',
            'scrambled': ['R', 'A', 'L', 'O', 'S'],
            'category': '🌌 Astronomy',
            'hint': 'Related to the Sun.',
          },
          {
            'word': 'CYCLE',
            'scrambled': ['E', 'L', 'C', 'Y', 'C'],
            'category': '🔄 Science',
            'hint': 'A series of events that repeat.',
          },
          {
            'word': 'FOSSIL',
            'scrambled': ['L', 'I', 'S', 'S', 'O', 'F'],
            'category': '🦴 Geology',
            'hint': 'Preserved remains of ancient life.',
          }
        ];
        break;
      case 5:
        baseLevels = [
          {
            'word': 'ANIMAL',
            'scrambled': ['L', 'A', 'M', 'I', 'N', 'A'],
            'category': '🦁 Biology',
            'hint': 'Living creature that can move and feels.',
          },
          {
            'word': 'ENERGY',
            'scrambled': ['Y', 'G', 'R', 'E', 'N', 'E'],
            'category': '⚡ Physics',
            'hint': 'The capacity to do work.',
          },
          {
            'word': 'MAGNET',
            'scrambled': ['T', 'N', 'E', 'G', 'A', 'M'],
            'category': '🧲 Physics',
            'hint': 'Object that attracts iron.',
          },
          {
            'word': 'CLIMATE',
            'scrambled': ['E', 'T', 'A', 'M', 'I', 'L', 'C'],
            'category': '🌍 Geography',
            'hint': 'Average weather over long periods.',
          },
          {
            'word': 'VOLCANO',
            'scrambled': ['O', 'N', 'A', 'C', 'L', 'O', 'V'],
            'category': '🌋 Geology',
            'hint': 'Mountain that erupts lava.',
          },
          {
            'word': 'PLASTIC',
            'scrambled': ['C', 'I', 'T', 'S', 'A', 'L', 'P'],
            'category': '🥤 Materials',
            'hint': 'Synthetic polymer material.',
          },
          {
            'word': 'GRAVITY',
            'scrambled': ['Y', 'T', 'I', 'V', 'A', 'R', 'G'],
            'category': '🌌 Physics',
            'hint': 'Force pulling objects down.',
          },
          {
            'word': 'WEATHER',
            'scrambled': ['R', 'E', 'H', 'T', 'A', 'E', 'W'],
            'category': '☁️ Weather',
            'hint': 'Daily temperature and rain.',
          },
          {
            'word': 'SPECIES',
            'scrambled': ['S', 'E', 'I', 'C', 'E', 'P', 'S'],
            'category': '🧬 Biology',
            'hint': 'Group of similar organisms.',
          },
          {
            'word': 'GLACIER',
            'scrambled': ['R', 'E', 'I', 'C', 'A', 'L', 'G'],
            'category': '🏔️ Geography',
            'hint': 'Slowly moving river of ice.',
          }
        ];
        break;
      case 6:
        baseLevels = [
          {
            'word': 'OXYGEN',
            'scrambled': ['G', 'E', 'X', 'Y', 'O', 'N'],
            'category': '🌿 Biology',
            'hint': 'Gas essential for human respiration.',
          },
          {
            'word': 'FOREST',
            'scrambled': ['T', 'S', 'E', 'R', 'O', 'F'],
            'category': '🌳 Ecology',
            'hint': 'Large area covered chiefly with trees.',
          },
          {
            'word': 'CHEMICAL',
            'scrambled': ['L', 'A', 'C', 'I', 'M', 'E', 'H', 'C'],
            'category': '🧪 Chemistry',
            'hint': 'Substance with distinct properties.',
          },
          {
            'word': 'ELECTRON',
            'scrambled': ['N', 'O', 'R', 'T', 'C', 'E', 'L', 'E'],
            'category': '⚛️ Physics',
            'hint': 'Negatively charged subatomic particle.',
          },
          {
            'word': 'PROTON',
            'scrambled': ['N', 'O', 'T', 'O', 'R', 'P'],
            'category': '⚛️ Physics',
            'hint': 'Positively charged subatomic particle.',
          },
          {
            'word': 'NEUTRON',
            'scrambled': ['N', 'O', 'R', 'T', 'U', 'E', 'N'],
            'category': '⚛️ Physics',
            'hint': 'Neutral subatomic particle in nucleus.',
          },
          {
            'word': 'NUCLEUS',
            'scrambled': ['S', 'U', 'E', 'L', 'C', 'U', 'N'],
            'category': '🧬 Biology',
            'hint': 'The central core of a cell.',
          },
          {
            'word': 'CELLULAR',
            'scrambled': ['R', 'A', 'L', 'U', 'L', 'E', 'C'],
            'category': '🧬 Biology',
            'hint': 'Relating to cells.',
          },
          {
            'word': 'ECOLOGY',
            'scrambled': ['Y', 'G', 'O', 'L', 'O', 'C', 'E'],
            'category': '🌳 Science',
            'hint': 'Study of organisms and environment.',
          },
          {
            'word': 'HABITAT',
            'scrambled': ['T', 'A', 'T', 'I', 'B', 'A', 'H'],
            'category': '🦁 Ecology',
            'hint': 'Natural home of an organism.'
          }
        ];
        break;
      case 7:
        baseLevels = [
          {
            'word': 'ALGEBRA',
            'scrambled': ['G', 'E', 'R', 'B', 'L', 'A', 'A'],
            'category': '📐 Math',
            'hint': 'The branch of mathematics involving variables.',
          },
          {
            'word': 'LIQUID',
            'scrambled': ['D', 'I', 'U', 'Q', 'I', 'L'],
            'category': '🧪 Chemistry',
            'hint': 'State of matter between solid and gas.',
          },
          {
            'word': 'FRACTION',
            'scrambled': ['N', 'O', 'I', 'T', 'C', 'A', 'R', 'F'],
            'category': '📐 Math',
            'hint': 'Part of a whole number.',
          },
          {
            'word': 'DECIMAL',
            'scrambled': ['L', 'A', 'M', 'I', 'C', 'E', 'D'],
            'category': '📐 Math',
            'hint': 'Fraction expressed in base-10 notation.',
          },
          {
            'word': 'PERCENT',
            'scrambled': ['T', 'N', 'E', 'C', 'R', 'E', 'P'],
            'category': '📐 Math',
            'hint': 'Ratio out of one hundred.',
          },
          {
            'word': 'GEOMETRY',
            'scrambled': ['Y', 'R', 'T', 'E', 'M', 'O', 'E', 'G'],
            'category': '📐 Math',
            'hint': 'Study of lines, angles, shapes.',
          },
          {
            'word': 'EQUATION',
            'scrambled': ['N', 'O', 'I', 'T', 'A', 'U', 'Q', 'E'],
            'category': '📐 Math',
            'hint': 'Mathematical statement of equality.',
          },
          {
            'word': 'VARIABLE',
            'scrambled': ['E', 'L', 'B', 'A', 'I', 'R', 'A', 'V'],
            'category': '💻 Coding',
            'hint': 'Symbol representing a value.',
          },
          {
            'word': 'TRIANGLE',
            'scrambled': ['E', 'L', 'G', 'N', 'A', 'I', 'R', 'T'],
            'category': '📐 Math',
            'hint': 'Three-sided polygon.',
          },
          {
            'word': 'SYMMETRY',
            'scrambled': ['Y', 'R', 'T', 'E', 'M', 'M', 'Y', 'S'],
            'category': '📐 Math',
            'hint': 'Balanced proportion in halves.'
          }
        ];
        break;
      case 8:
        baseLevels = [
          {
            'word': 'GRAVITY',
            'scrambled': ['V', 'I', 'R', 'T', 'G', 'Y', 'A'],
            'category': '🌌 Physics',
            'hint': 'The invisible force that pulls objects toward each other.',
          },
          {
            'word': 'FORCE',
            'scrambled': ['E', 'C', 'R', 'O', 'F'],
            'category': '⚡ Physics',
            'hint': 'A push or pull acting upon an object.',
          },
          {
            'word': 'ORGANISM',
            'scrambled': ['M', 'S', 'I', 'N', 'A', 'G', 'R', 'O'],
            'category': '🌿 Biology',
            'hint': 'An individual living thing.',
          },
          {
            'word': 'ECOSYSTEM',
            'scrambled': ['M', 'E', 'T', 'S', 'Y', 'S', 'O', 'C', 'E'],
            'category': '🌳 Ecology',
            'hint': 'Community of interacting organisms.',
          },
          {
            'word': 'POLLUTION',
            'scrambled': ['N', 'O', 'I', 'T', 'U', 'L', 'L', 'O', 'P'],
            'category': '🌳 Ecology',
            'hint': 'Harmful materials in environment.',
          },
          {
            'word': 'RESOURCE',
            'scrambled': ['E', 'C', 'R', 'U', 'O', 'S', 'E', 'R'],
            'category': '🌍 geography',
            'hint': 'Source of supply or support.',
          },
          {
            'word': 'RECYCLING',
            'scrambled': ['G', 'N', 'I', 'L', 'C', 'Y', 'C', 'E', 'R'],
            'category': '♻️ Ecology',
            'hint': 'Converting waste into reusable material.',
          },
          {
            'word': 'ATMOSPHERE',
            'scrambled': ['E', 'R', 'E', 'H', 'P', 'S', 'O', 'M', 'T', 'A'],
            'category': '☁️ Science',
            'hint': 'Layer of gases surrounding Earth.',
          },
          {
            'word': 'EVOLUTION',
            'scrambled': ['N', 'O', 'I', 'T', 'U', 'L', 'O', 'V', 'E'],
            'category': '🧬 Biology',
            'hint': 'Development of species over time.',
          },
          {
            'word': 'PRESSURE',
            'scrambled': ['E', 'R', 'U', 'S', 'S', 'E', 'R', 'P'],
            'category': '🧪 Physics',
            'hint': 'Force per unit area.'
          }
        ];
        break;
      case 9:
        baseLevels = [
          {
            'word': 'CHROMOSOME',
            'scrambled': ['C', 'H', 'R', 'O', 'M', 'O', 'S', 'O', 'M', 'E'],
            'category': '🌿 Biology',
            'hint': 'Thread-like structure carrying genetic information.',
          },
          {
            'word': 'POLYMER',
            'scrambled': ['R', 'E', 'M', 'Y', 'L', 'O', 'P'],
            'category': '🧪 Chemistry',
            'hint': 'Large molecule composed of repeating structural units.',
          },
          {
            'word': 'GENETICS',
            'scrambled': ['S', 'C', 'I', 'T', 'E', 'N', 'E', 'G'],
            'category': '🧬 Biology',
            'hint': 'Study of heredity and variation.',
          },
          {
            'word': 'MUTATION',
            'scrambled': ['N', 'O', 'I', 'T', 'A', 'T', 'U', 'M'],
            'category': '🧬 Biology',
            'hint': 'Alteration in DNA sequence.',
          },
          {
            'word': 'RESONANCE',
            'scrambled': ['E', 'C', 'N', 'A', 'N', 'O', 'S', 'E', 'R'],
            'category': '🔊 Physics',
            'hint': 'Vibrational reinforcement.',
          },
          {
            'word': 'COMPOUND',
            'scrambled': ['D', 'N', 'U', 'O', 'P', 'M', 'O', 'C'],
            'category': '🧪 Chemistry',
            'hint': 'Substance of two or more elements.',
          },
          {
            'word': 'MOLECULE',
            'scrambled': ['E', 'L', 'U', 'C', 'E', 'L', 'O', 'M'],
            'category': '🧪 Chemistry',
            'hint': 'Group of bonded atoms.',
          },
          {
            'word': 'VELOCITY',
            'scrambled': ['Y', 'T', 'I', 'C', 'O', 'L', 'E', 'V'],
            'category': '⚡ Physics',
            'hint': 'Speed in a given direction.',
          },
          {
            'word': 'INERTIA',
            'scrambled': ['A', 'I', 'T', 'R', 'E', 'N', 'I'],
            'category': '⚡ Physics',
            'hint': 'Resistance to change in motion.',
          },
          {
            'word': 'FRICTION',
            'scrambled': ['N', 'O', 'I', 'T', 'C', 'I', 'R', 'F'],
            'category': '⚡ Physics',
            'hint': 'Force resisting sliding.'
          }
        ];
        break;
      case 10:
        baseLevels = [
          {
            'word': 'SYNTAX',
            'scrambled': ['X', 'A', 'T', 'N', 'Y', 'S'],
            'category': '💻 Coding',
            'hint': 'Set of rules defining the structure of statements in coding.',
          },
          {
            'word': 'COMPILER',
            'scrambled': ['R', 'E', 'L', 'I', 'P', 'M', 'O', 'C'],
            'category': '💻 Computer Science',
            'hint': 'Program that translates code into machine language.',
          },
          {
            'word': 'DATABASE',
            'scrambled': ['E', 'S', 'A', 'B', 'A', 'T', 'A', 'D'],
            'category': '💻 Coding',
            'hint': 'Structured set of stored data.',
          },
          {
            'word': 'ALGORITHM',
            'scrambled': ['M', 'H', 'T', 'I', 'R', 'O', 'G', 'L', 'A'],
            'category': '💻 Computer Science',
            'hint': 'Step-by-step problem-solving procedure.',
          },
          {
            'word': 'INSULATOR',
            'scrambled': ['R', 'O', 'T', 'A', 'L', 'U', 'S', 'N', 'I'],
            'category': '🔌 Electronics',
            'hint': 'Material resisting electrical current flow.',
          },
          {
            'word': 'RESISTOR',
            'scrambled': ['R', 'O', 'T', 'S', 'I', 'S', 'E', 'R'],
            'category': '🔌 Electronics',
            'hint': 'Component limiting electric current.',
          },
          {
            'word': 'CAPACITOR',
            'scrambled': ['R', 'O', 'T', 'I', 'C', 'A', 'P', 'A', 'C'],
            'category': '🔌 Electronics',
            'hint': 'Component storing electrical energy.',
          },
          {
            'word': 'INDUCTOR',
            'scrambled': ['R', 'O', 'T', 'C', 'U', 'D', 'N', 'I'],
            'category': '🔌 Electronics',
            'hint': 'Component storing magnetic energy.',
          },
          {
            'word': 'TRANSISTOR',
            'scrambled': ['R', 'O', 'T', 'S', 'I', 'S', 'N', 'A', 'R', 'T'],
            'category': '🔌 Electronics',
            'hint': 'Semiconductor device for switching.',
          },
          {
            'word': 'PROTOCOL',
            'scrambled': ['L', 'O', 'C', 'O', 'T', 'O', 'R', 'P'],
            'category': '💻 Networking',
            'hint': 'Set of rules for data communication.'
          }
        ];
        break;
      case 11:
        baseLevels = [
          {
            'word': 'PHOTOSYNTHESIS',
            'scrambled': ['P', 'H', 'O', 'T', 'O', 'S', 'Y', 'N', 'T', 'H', 'E', 'S', 'I', 'S'],
            'category': '🌿 Biology',
            'hint': 'Process plants use to make food from sunlight.',
          },
          {
            'word': 'REACTION',
            'scrambled': ['N', 'O', 'I', 'T', 'C', 'A', 'E', 'R'],
            'category': '🧪 Chemistry',
            'hint': 'Process that leads to chemical transformation of substances.',
          },
          {
            'word': 'RESPIRATION',
            'scrambled': ['N', 'O', 'I', 'T', 'A', 'R', 'I', 'P', 'S', 'E', 'R'],
            'category': '🌿 Biology',
            'hint': 'Cellular energy production.',
          },
          {
            'word': 'HYDROCARBON',
            'scrambled': ['N', 'O', 'B', 'R', 'A', 'C', 'O', 'R', 'D', 'Y', 'H'],
            'category': '🧪 Chemistry',
            'hint': 'Organic compound of hydrogen and carbon.',
          },
          {
            'word': 'CARBOHYDRATE',
            'scrambled': ['E', 'T', 'A', 'R', 'D', 'Y', 'H', 'O', 'B', 'R', 'A', 'C'],
            'category': '🧪 Chemistry',
            'hint': 'Sugar, starch, or cellulose biomolecule.',
          },
          {
            'word': 'ELECTROMAGNET',
            'scrambled': ['T', 'E', 'N', 'G', 'A', 'M', 'O', 'R', 'T', 'C', 'E', 'L', 'E'],
            'category': '⚡ Physics',
            'hint': 'Magnet run by electric current.'
          },
          {
            'word': 'RELATIVITY',
            'scrambled': ['Y', 'T', 'I', 'V', 'I', 'T', 'A', 'L', 'E', 'R'],
            'category': '🌌 Physics',
            'hint': 'Einstein\'s theory of space and time.'
          },
          {
            'word': 'GRAVITATION',
            'scrambled': ['N', 'O', 'I', 'T', 'A', 'T', 'I', 'V', 'A', 'R', 'G'],
            'category': '🌌 Physics',
            'hint': 'Universal force of attraction.'
          },
          {
            'word': 'KINETICS',
            'scrambled': ['S', 'C', 'I', 'T', 'E', 'N', 'I', 'K'],
            'category': '🧪 Chemistry',
            'hint': 'Study of reaction rates.'
          },
          {
            'word': 'EQUILIBRIUM',
            'scrambled': ['M', 'U', 'I', 'R', 'B', 'I', 'L', 'I', 'Q', 'U', 'E'],
            'category': '🧪 Chemistry',
            'hint': 'State of balance in reactions.'
          }
        ];
        break;
      case 12:
      default:
        baseLevels = [
          {
            'word': 'SEMICONDUCTOR',
            'scrambled': ['S', 'E', 'M', 'I', 'C', 'O', 'N', 'D', 'U', 'C', 'T', 'O', 'R'],
            'category': '🔌 Electronics',
            'hint': 'Electrical conductivity between a conductor and insulator.',
          },
          {
            'word': 'THERMODYNAMICS',
            'scrambled': ['T', 'H', 'E', 'R', 'M', 'O', 'D', 'Y', 'N', 'A', 'M', 'I', 'C', 'S'],
            'category': '⚛️ Physics',
            'hint': 'Branch of physics dealing with heat and temperature.',
          },
          {
            'word': 'BIOCHEMISTRY',
            'scrambled': ['Y', 'R', 'T', 'S', 'I', 'M', 'E', 'H', 'C', 'O', 'I', 'B'],
            'category': '🧪 Chemistry',
            'hint': 'Chemical processes within living organisms.',
          },
          {
            'word': 'ASTROPHYSICS',
            'scrambled': ['S', 'C', 'I', 'S', 'Y', 'H', 'P', 'O', 'R', 'T', 'S', 'A'],
            'category': '🌌 Physics',
            'hint': 'Physics of celestial bodies.',
          },
          {
            'word': 'CRYPTOGRAPHY',
            'scrambled': ['Y', 'H', 'P', 'A', 'R', 'G', 'O', 'T', 'P', 'Y', 'R', 'C'],
            'category': '💻 Computer Science',
            'hint': 'Practice of secure communication.',
          },
          {
            'word': 'ALGORITHM',
            'scrambled': ['M', 'H', 'T', 'I', 'R', 'O', 'G', 'L', 'A'],
            'category': '💻 Computer Science',
            'hint': 'Step-by-step calculation procedure.',
          },
          {
            'word': 'COMPILATION',
            'scrambled': ['N', 'O', 'I', 'T', 'A', 'L', 'I', 'P', 'M', 'O', 'C'],
            'category': '💻 Computer Science',
            'hint': 'Translating source code to executable.',
          },
          {
            'word': 'INTERPRETATION',
            'scrambled': ['N', 'O', 'I', 'T', 'A', 'T', 'E', 'R', 'P', 'R', 'E', 'T', 'N', 'I'],
            'category': '💻 Computer Science',
            'hint': 'Executing code line-by-step.'
          },
          {
            'word': 'RADIOACTIVITY',
            'scrambled': ['Y', 'T', 'I', 'V', 'I', 'T', 'C', 'A', 'O', 'I', 'D', 'A', 'R'],
            'category': '⚛️ Physics',
            'hint': 'Spontaneous emission of radiation.'
          },
          {
            'word': 'SUPERCONDUCTOR',
            'scrambled': ['R', 'O', 'T', 'C', 'U', 'D', 'N', 'O', 'C', 'R', 'E', 'P', 'U', 'S'],
            'category': '🔌 Electronics',
            'hint': 'Material with zero electrical resistance.'
          }
        ];
        break;
    }

    final state = Provider.of<AppState>(context, listen: false);
    final customLevels = state.customUnscrambleLevels
        .where((lvl) => lvl['class'] == _selectedClass)
        .map((lvl) {
          return {
            'word': lvl['word'],
            'scrambled': List<String>.from(lvl['scrambled']),
            'category': lvl['category'],
            'hint': lvl['hint'],
          };
        }).toList();

    return [...baseLevels, ...customLevels];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    // Start quiz timer on load
    WidgetsBinding.instance.addPostFrameCallback((_) => _startQuizTimer());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    _quizTimer?.cancel();
    _cognitiveTimer?.cancel();
    super.dispose();
  }

  // ── Quiz Timer ─────────────────────────────────────────────────────
  void _startQuizTimer() {
    _quizTimer?.cancel();
    _quizTimeLeft = 15;
    _quizTimeOut = false;
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_quizTimeLeft > 0) {
          _quizTimeLeft--;
        } else {
          t.cancel();
          _quizTimeOut = true;
          _quizAnswered = true;
          _quizStreak = 0;        // streak breaks on timeout
          if (_quizLives > 0) _quizLives--;
        }
      });
    });
  }

  // ── Cognitive Timer ────────────────────────────────────────────────
  void _startCognitiveTimer() {
    _cognitiveTimer?.cancel();
    _cognitiveTimeLeft = 20;
    _cognitiveTimeOut = false;
    _cognitiveTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_cognitiveTimeLeft > 0) {
          _cognitiveTimeLeft--;
        } else {
          t.cancel();
          _cognitiveTimeOut = true;
          _cognitiveSolved = true;
        }
      });
    });
  }

  void _triggerWin() {
    _confettiController.play();
  }

  // ── Shuffle syntax tiles when level loads ─────────────────────────
  void _initSyntaxLevel(List<String> tiles) {
    final shuffled = List<String>.from(tiles);
    shuffled.shuffle(Random());
    _shuffledSyntaxTiles = shuffled;
    _assembledSyntax = [];
    _syntaxWrongAttempts = 0;
    _syntaxLevelCompleted = false;
  }

  // DIALOG PORTAL TO ADD CUSTOM QUESTIONS DYNAMICALLY
  void _showAddQuestionDialog() {
    final questionController = TextEditingController();
    final option0Controller = TextEditingController();
    final option1Controller = TextEditingController();
    final option2Controller = TextEditingController();
    final option3Controller = TextEditingController();
    int selectedCorrectIndex = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                '➕ Add Custom Question',
                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: AdyapanTheme.blueAccent),
              ),
              content: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create your own custom question to test your knowledge in the Quiz Arena!',
                      style: GoogleFonts.outfit(fontSize: 11, color: AdyapanTheme.textSub),
                    ),
                    const SizedBox(height: 14),
                    // Question text
                    TextField(
                      controller: questionController,
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        labelText: 'Question Text',
                        labelStyle: GoogleFonts.outfit(fontSize: 12, color: AdyapanTheme.textSub),
                        hintText: 'e.g. What is 7 * 6?',
                        hintStyle: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Option 0
                    _buildOptionInputField(option0Controller, 'Option A (Index 0)', 'e.g. 42'),
                    const SizedBox(height: 8),
                    // Option 1
                    _buildOptionInputField(option1Controller, 'Option B (Index 1)', 'e.g. 49'),
                    const SizedBox(height: 8),
                    // Option 2
                    _buildOptionInputField(option2Controller, 'Option C (Index 2)', 'e.g. 35'),
                    const SizedBox(height: 8),
                    // Option 3
                    _buildOptionInputField(option3Controller, 'Option D (Index 3)', 'e.g. 56'),
                    const SizedBox(height: 12),
                    
                    // Correct index dropdown
                    DropdownButtonFormField<int>(
                      value: selectedCorrectIndex,
                      decoration: InputDecoration(
                        labelText: 'Correct Option',
                        labelStyle: GoogleFonts.outfit(fontSize: 12, color: AdyapanTheme.textSub),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Option A', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 1, child: Text('Option B', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 2, child: Text('Option C', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 3, child: Text('Option D', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedCorrectIndex = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.fredoka(color: AdyapanTheme.textSub)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final qText = questionController.text.trim();
                    final opt0 = option0Controller.text.trim();
                    final opt1 = option1Controller.text.trim();
                    final opt2 = option2Controller.text.trim();
                    final opt3 = option3Controller.text.trim();

                    if (qText.isNotEmpty && opt0.isNotEmpty && opt1.isNotEmpty && opt2.isNotEmpty && opt3.isNotEmpty) {
                      Provider.of<AppState>(context, listen: false).addCustomQuizQuestion(
                        question: qText,
                        options: [opt0, opt1, opt2, opt3],
                        correctOptionIndex: selectedCorrectIndex,
                        targetClass: _selectedClass,
                      );
                      setState(() {});
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎉 Custom question successfully added to Quiz Arena!'),
                          backgroundColor: AdyapanTheme.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚠️ Please fill in all options!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdyapanTheme.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  child: Text('Add Question', style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOptionInputField(TextEditingController controller, String label, String hint) {
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(fontSize: 12, color: AdyapanTheme.textSub),
        hintText: hint,
        hintStyle: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildQuizArena() {
    final state = Provider.of<AppState>(context);
    final activeQuestions = [
      ..._getQuizQuestions(),
      ...state.customQuizQuestions
          .where((q) => q['class'] == null || q['class'] == _selectedClass)
          .map((q) => {
        'question': q['question'],
        'options': List<String>.from(q['options']),
        'correctIdx': q['correctOptionIndex'],
      })
    ];

    if (_currentQuizIdx >= activeQuestions.length) _currentQuizIdx = 0;
    if (_quizLives <= 0) {
      // Game Over screen
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Text('💀', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text('Game Over!', style: AdyapanTheme.fredoka(fontSize: 28, fontWeight: FontWeight.bold, color: AdyapanTheme.pink)),
          const SizedBox(height: 8),
          Text('Final Score: $_quizScore pts', style: AdyapanTheme.fredoka(fontSize: 18, color: AdyapanTheme.textSub)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: Text('Play Again', style: AdyapanTheme.fredoka(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdyapanTheme.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              minimumSize: const Size(double.infinity, 52),
            ),
            onPressed: () {
              setState(() {
                _quizLives = 3;
                _quizScore = 0;
                _quizStreak = 0;
                _currentQuizIdx = 0;
                _selectedAnswerIdx = null;
                _quizAnswered = false;
                _quizTimeOut = false;
              });
              _startQuizTimer();
            },
          ),
        ],
      );
    }

    var q = activeQuestions[_currentQuizIdx];

    // Streak multiplier display
    final int multiplier = _quizStreak >= 5 ? 3 : (_quizStreak >= 3 ? 2 : 1);
    final String streakLabel = multiplier == 3 ? '🔥🔥🔥 3× BONUS!' : (multiplier == 2 ? '🔥🔥 2× BONUS!' : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top bar: Lives + Score + Streak ──
        Row(
          children: [
            // Lives
            Row(
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Text(
                  i < _quizLives ? '❤️' : '🖤',
                  style: const TextStyle(fontSize: 18),
                ),
              )),
            ),
            const Spacer(),
            Text('Score: $_quizScore', style: AdyapanTheme.fredoka(fontSize: 13, color: AdyapanTheme.green, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Text('Q${_currentQuizIdx + 1}/${activeQuestions.length}', style: AdyapanTheme.fredoka(fontSize: 13, color: AdyapanTheme.blueAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        if (streakLabel.isNotEmpty) ...[
          const SizedBox(height: 4),
          Center(child: Text(streakLabel, style: AdyapanTheme.fredoka(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.bold))),
        ],
        const SizedBox(height: 10),

        // ── Timer bar ──
        Row(
          children: [
            Text(
              '⏱️ ${_quizTimeLeft}s',
              style: AdyapanTheme.fredoka(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _quizTimeLeft <= 5 ? AdyapanTheme.pink : AdyapanTheme.textMain,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _quizTimeLeft / 15,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _quizTimeLeft <= 5 ? AdyapanTheme.pink : AdyapanTheme.blueAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Question card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: AdyapanTheme.glassCardDecoration(customBg: AdyapanTheme.bgLightDark),
          child: Text(
            q['question'],
            style: AdyapanTheme.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),

        // ── Answer options ──
        ...List.generate(q['options'].length, (index) {
          bool isSelected = _selectedAnswerIdx == index;
          bool isCorrect  = index == q['correctIdx'];
          Color tileBg     = Colors.white;
          Color tileBorder = AdyapanTheme.glassBorder;
          Color textColor  = AdyapanTheme.textMain;

          if (_quizAnswered) {
            if (isCorrect) {
              tileBg = AdyapanTheme.green.withOpacity(0.08);
              tileBorder = AdyapanTheme.green;
              textColor  = AdyapanTheme.green;
            } else if (isSelected) {
              tileBg = AdyapanTheme.pink.withOpacity(0.08);
              tileBorder = AdyapanTheme.pink;
              textColor  = AdyapanTheme.pink;
            }
          } else if (isSelected) {
            tileBorder = AdyapanTheme.blueAccent;
            tileBg     = AdyapanTheme.blueAccent.withOpacity(0.05);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: _quizAnswered ? null : () => setState(() => _selectedAnswerIdx = index),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: tileBg,
                  border: Border.all(color: tileBorder, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(q['options'][index], style: AdyapanTheme.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: textColor))),
                    if (_quizAnswered && isCorrect)
                      const Icon(Icons.check_circle_rounded, color: AdyapanTheme.green, size: 20)
                    else if (_quizAnswered && isSelected && !isCorrect)
                      const Icon(Icons.cancel_rounded, color: AdyapanTheme.pink, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),

        if (_quizTimeOut && !_quizAnswered)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AdyapanTheme.pink.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.timer_off_rounded, color: AdyapanTheme.pink),
              const SizedBox(width: 8),
              Text('Time\'s up! -1 ❤️', style: AdyapanTheme.fredoka(color: AdyapanTheme.pink, fontWeight: FontWeight.bold)),
            ]),
          ),

        const SizedBox(height: 8),
        if (!_quizAnswered)
          ElevatedButton(
            onPressed: _selectedAnswerIdx == null ? null : () {
              _quizTimer?.cancel();
              final bool correct = _selectedAnswerIdx == q['correctIdx'];
              setState(() {
                _quizAnswered = true;
                if (correct) {
                  _quizStreak++;
                  final pts = 10 * multiplier;
                  _quizScore += pts;
                  _triggerWin();
                } else {
                  _quizStreak = 0;
                  _quizLives--;
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdyapanTheme.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              minimumSize: const Size(double.infinity, 50),
              elevation: 4,
            ),
            child: Text('Submit Answer', style: AdyapanTheme.fredoka(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        else
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (_currentQuizIdx + 1 < activeQuestions.length) {
                  _currentQuizIdx++;
                  _selectedAnswerIdx = null;
                  _quizAnswered = false;
                  _quizTimeOut = false;
                } else {
                  _currentQuizIdx = 0;
                  _selectedAnswerIdx = null;
                  _quizAnswered = false;
                  _quizTimeOut = false;
                }
              });
              _startQuizTimer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdyapanTheme.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(
              _currentQuizIdx + 1 < activeQuestions.length ? 'Next Question ➜' : '🔄 Restart Quiz',
              style: AdyapanTheme.fredoka(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
      ],
    );
  }


  Widget _buildCognitiveLogicArena() {
    final levels = _getCognitiveLevels();
    if (_currentCognitiveLevel >= levels.length) _currentCognitiveLevel = 0;
    final level = levels[_currentCognitiveLevel];
    final type = level['type'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              type == 'spatial' ? 'Matrix Rotation 🔄' : (type == 'flow' ? 'Flow Processor ⚙️' : 'Pathfinder 🤖'),
              style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            ),
            Row(children: [
              // ⏱️ Timer badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _cognitiveTimeLeft <= 6 ? AdyapanTheme.pink.withOpacity(0.12) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _cognitiveTimeLeft <= 6 ? AdyapanTheme.pink : Colors.orange.withOpacity(0.4)),
                ),
                child: Text(
                  '⏱️ ${_cognitiveTimeLeft}s',
                  style: GoogleFonts.fredoka(fontSize: 10.5, fontWeight: FontWeight.bold,
                    color: _cognitiveTimeLeft <= 6 ? AdyapanTheme.pink : Colors.orange.shade800),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                ),
                child: Text(
                  'Level ${_currentCognitiveLevel + 1}/${levels.length}',
                  style: GoogleFonts.fredoka(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                ),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 6),
        // Timer progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _cognitiveTimeLeft / 20,
            minHeight: 5,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(
              _cognitiveTimeLeft <= 6 ? AdyapanTheme.pink : Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_cognitiveTimeOut && !_cognitiveSolved)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AdyapanTheme.pink.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Text('⏰ Time\'s Up! Correct answer revealed.', style: GoogleFonts.outfit(fontSize: 12, color: AdyapanTheme.pink, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(height: 6),
        Text(
          level['question'] as String,
          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        if (type == 'spatial' && level.containsKey('original')) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.75), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]
            ),
            child: Column(children: [
              Text('Original shape:', style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
              const SizedBox(height: 8),
              Text(level['original'] as String, style: const TextStyle(fontSize: 72, color: Color(0xFF1E293B))),
            ]),
          ),
          const SizedBox(height: 24),
        ] else if (type == 'flow' && level.containsKey('flow')) ...[
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.75), width: 1.5),
            ),
            child: Column(children: [
              Text('Accenture Logical Circuit Flowchart:', style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                  child: Text('Input: ${level['input']}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold))),
                const Icon(Icons.arrow_forward_rounded, color: Color(0xFF64748B), size: 16),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                  child: Text('[+4]', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold))),
                const Icon(Icons.arrow_forward_rounded, color: Color(0xFF64748B), size: 16),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                  child: Text('[/2]', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: 8),
              const Icon(Icons.arrow_downward_rounded, color: Color(0xFF64748B), size: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                child: Text('Condition: If Value > 5 ➔ Output\nElse ➔ Output * 2', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            ]),
          ),
          const SizedBox(height: 24),
        ] else if (type == 'pathfinder') ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.75), width: 1.5),
            ),
            child: Column(children: [
              Text('3x3 Navigation Matrix Grid:', style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
              const SizedBox(height: 12),
              Table(
                border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 1),
                defaultColumnWidth: const FixedColumnWidth(40),
                children: [
                  TableRow(children: [
                    Container(height: 40, alignment: Alignment.center, child: const Text('🏁', style: TextStyle(fontSize: 16))),
                    Container(height: 40), Container(height: 40),
                  ]),
                  TableRow(children: [Container(height: 40), Container(height: 40), Container(height: 40)]),
                  TableRow(children: [
                    Container(height: 40, alignment: Alignment.center, child: const Text('🤖', style: TextStyle(fontSize: 16))),
                    Container(height: 40), Container(height: 40),
                  ]),
                ],
              ),
              const SizedBox(height: 8),
              Text('Start: bottom-left (🤖) → Destination: top-right (🏁)', style: GoogleFonts.outfit(fontSize: 9.5, color: const Color(0xFF64748B))),
            ]),
          ),
          const SizedBox(height: 24),
        ],

        Text('Select the correct answer:', style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
        const SizedBox(height: 12),
        Column(
          children: (level['choices'] as List<String>).map((choice) {
            final isSelected = _selectedCognitiveChoice == choice;
            final isCorrect  = choice == level['correct'];
            Color btnColor = Colors.white;
            Color textColor = const Color(0xFF1E293B);
            BorderSide border = const BorderSide(color: Color(0xFFE2E8F0), width: 1.5);

            if (_cognitiveSolved) {
              if (isCorrect) { btnColor = const Color(0xFFECFDF5); textColor = const Color(0xFF059669); border = const BorderSide(color: Color(0xFF10B981), width: 1.5); }
              else if (isSelected) { btnColor = const Color(0xFFFEF2F2); textColor = const Color(0xFFDC2626); border = const BorderSide(color: Color(0xFFEF4444), width: 1.5); }
            } else if (isSelected) {
              btnColor = const Color(0xFFEFF6FF); textColor = const Color(0xFF2563EB); border = const BorderSide(color: Color(0xFF3B82F6), width: 1.5);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: _cognitiveSolved ? null : () => setState(() => _selectedCognitiveChoice = choice),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor, surfaceTintColor: Colors.transparent,
                    elevation: isSelected ? 1 : 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), side: border,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(choice, style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor)),
                      if (_cognitiveSolved && isCorrect) const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                      else if (_cognitiveSolved && isSelected) const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20)
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        if (!_cognitiveSolved)
          ElevatedButton(
            onPressed: _selectedCognitiveChoice == null ? null : () {
              _cognitiveTimer?.cancel();
              setState(() { _cognitiveSolved = true;
                if (_selectedCognitiveChoice == level['correct']) _triggerWin();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB), minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), elevation: 2,
            ),
            child: Text('Submit Answer 🤖', style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(14), width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBFDBFE))),
            child: Row(children: [
              const Text('💡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('EXPLANATION:', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF1D4ED8), letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(level['desc'] as String, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF1E3A8A), height: 1.3)),
              ])),
            ]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _cognitiveSolved = false; _selectedCognitiveChoice = null; _cognitiveTimeOut = false;
                if (_currentCognitiveLevel + 1 < levels.length) _currentCognitiveLevel++;
                else _currentCognitiveLevel = 0;
              });
              _startCognitiveTimer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981), minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
            child: Text(
              _currentCognitiveLevel + 1 < levels.length ? 'Next Challenge' : '🔄 Restart Cognitive Arena',
              style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildSyntaxBlocks() {
    final levels = _getSyntaxLevels();
    if (_currentSyntaxLevel >= levels.length) _currentSyntaxLevel = 0;
    final level = levels[_currentSyntaxLevel];
    final String description = level['desc'] as String;
    final List<String> correctOrder = List<String>.from(level['correct']);

    // Init shuffled tiles on first render for this level
    if (_shuffledSyntaxTiles.isEmpty || _shuffledSyntaxTiles.length != correctOrder.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _initSyntaxLevel(level['tiles']));
      });
    }
    final tiles = _shuffledSyntaxTiles.isEmpty ? List<String>.from(level['tiles']) : _shuffledSyntaxTiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('🧩 Assemble the Code Blocks!', style: AdyapanTheme.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
            Row(children: [
              // ❌ Wrong attempts badge
              if (_syntaxWrongAttempts > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AdyapanTheme.pink.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text('❌ $_syntaxWrongAttempts wrong', style: AdyapanTheme.fredoka(fontSize: 10, color: AdyapanTheme.pink, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AdyapanTheme.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('Level ${_currentSyntaxLevel + 1}/${levels.length}', style: AdyapanTheme.fredoka(fontSize: 11, fontWeight: FontWeight.bold, color: AdyapanTheme.purple)),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 4),
        Text(description, style: AdyapanTheme.outfit(fontSize: 12, color: AdyapanTheme.textSub)),

        // 🔐 Difficulty hint: only show after 2+ wrong attempts
        if (_syntaxWrongAttempts >= 2) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text('Hint: First block is "${correctOrder.first}"', style: AdyapanTheme.outfit(fontSize: 11, color: Colors.orange.shade800))),
            ]),
          ),
        ],
        const SizedBox(height: 20),

        // Assembly Tray
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AdyapanTheme.bgLightDark,
            border: Border.all(color: _syntaxLevelCompleted ? AdyapanTheme.green : AdyapanTheme.glassBorder, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: _assembledSyntax.isEmpty
              ? Center(child: Text('Assembly Tray Empty — Tap blocks below!', style: AdyapanTheme.outfit(fontSize: 11, color: AdyapanTheme.textMuted)))
              : Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _assembledSyntax.asMap().entries.map((entry) {
                    final i = entry.key; final tile = entry.value;
                    // Color wrong-position tiles red before submission
                    final isWrongPos = !_syntaxLevelCompleted && i < correctOrder.length && tile != correctOrder[i];
                    return GestureDetector(
                      onTap: _syntaxLevelCompleted ? null : () => setState(() => _assembledSyntax.removeAt(i)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _syntaxLevelCompleted ? AdyapanTheme.green : (isWrongPos ? AdyapanTheme.pink : AdyapanTheme.purple),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(tile, style: AdyapanTheme.fredoka(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                          if (!_syntaxLevelCompleted) ...[ const SizedBox(width: 4), const Icon(Icons.close, color: Colors.white, size: 14) ],
                        ]),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 20),

        Text('Available Blocks:', style: AdyapanTheme.outfit(fontSize: 13, color: AdyapanTheme.textSub, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: tiles.map((tile) {
            final usedCount = _assembledSyntax.where((t) => t == tile).length;
            final totalInLevel = tiles.where((t) => t == tile).length;
            bool isFullyUsed = usedCount >= totalInLevel;
            return GestureDetector(
              onTap: isFullyUsed || _syntaxLevelCompleted ? null : () => setState(() => _assembledSyntax.add(tile)),
              child: Opacity(
                opacity: isFullyUsed ? 0.3 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AdyapanTheme.glassBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(tile, style: AdyapanTheme.fredoka(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _assembledSyntax.isEmpty ? null : () => setState(() => _assembledSyntax.clear()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
                  side: const BorderSide(color: AdyapanTheme.glassBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: Text('Reset', style: AdyapanTheme.fredoka(color: AdyapanTheme.textSub)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _assembledSyntax.isEmpty || _syntaxLevelCompleted ? null : () {
                  bool isCorrect = _assembledSyntax.length == correctOrder.length;
                  if (isCorrect) {
                    for (int i = 0; i < correctOrder.length; i++) {
                      if (_assembledSyntax[i] != correctOrder[i]) { isCorrect = false; break; }
                    }
                  }
                  if (isCorrect) {
                    _triggerWin();
                    setState(() => _syntaxLevelCompleted = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🎉 Code Compiled! Perfect Syntax!'), backgroundColor: AdyapanTheme.green),
                    );
                  } else {
                    setState(() => _syntaxWrongAttempts++);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Compile Error! Attempt #$_syntaxWrongAttempts — Reorder the blocks.'), backgroundColor: AdyapanTheme.pink),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdyapanTheme.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: Text('Compile Code ▶', style: AdyapanTheme.fredoka(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
        if (_syntaxLevelCompleted) ...[
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_currentSyntaxLevel + 1 < levels.length) _currentSyntaxLevel++;
                  else _currentSyntaxLevel = 0;
                  _initSyntaxLevel(levels[_currentSyntaxLevel < levels.length ? _currentSyntaxLevel : 0]['tiles']);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AdyapanTheme.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              child: Text(
                _currentSyntaxLevel + 1 < levels.length ? 'Next Level ▶' : '🔄 Restart Syntax Blocks',
                style: AdyapanTheme.fredoka(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ]
      ],
    );
  }

  Widget _buildWordUnscramble() {
    final levels = _getUnscrambleLevels();
    if (_currentUnscrambleLevel >= levels.length) _currentUnscrambleLevel = 0;
    final level = levels[_currentUnscrambleLevel];
    final String targetWord = level['word'];
    final List<String> scrambled = List<String>.from(level['scrambled']);
    final int maxWrong = 5;
    final bool outOfChances = _unscrambleWrongTaps >= maxWrong && !_unscrambleCompleted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Word Unscramble 🔠', style: AdyapanTheme.fredoka(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(children: [
              // Wrong attempts pip
              ...List.generate(maxWrong, (i) => Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(i < _unscrambleWrongTaps ? Icons.close_rounded : Icons.circle, color: i < _unscrambleWrongTaps ? AdyapanTheme.pink : AdyapanTheme.glassBorder, size: 12),
              )),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AdyapanTheme.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AdyapanTheme.blueAccent)),
                child: Text(level['category'] as String, style: AdyapanTheme.fredoka(fontSize: 10, fontWeight: FontWeight.bold, color: AdyapanTheme.blueAccent)),
              ),
            ])
          ],
        ),
        const SizedBox(height: 6),
        Row(children: [
          Text('Tap letter tiles to spell the word.', style: AdyapanTheme.outfit(fontSize: 12, color: AdyapanTheme.textSub)),
          const Spacer(),
          // Hint button (max 2 uses)
          if (_unscrambleHintsUsed < 2 && !_unscrambleCompleted)
            TextButton.icon(
              icon: const Icon(Icons.lightbulb_outline, size: 14, color: Colors.orange),
              label: Text('Hint (${2 - _unscrambleHintsUsed} left)', style: AdyapanTheme.outfit(fontSize: 11, color: Colors.orange)),
              onPressed: () => setState(() { _unscrambleHintsUsed++; _unscrambleShowHint = true; }),
            ),
        ]),
        const SizedBox(height: 16),

        // Hint card (shown only when activated)
        if (_unscrambleShowHint || outOfChances) ...[
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBFDBFE))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('HINT DEFINITION:', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF1D4ED8), letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text(level['hint'] as String, style: GoogleFonts.fredoka(fontSize: 13, color: const Color(0xFF1E3A8A))),
              if (outOfChances) ...[
                const SizedBox(height: 8),
                Text('Answer: $targetWord', style: GoogleFonts.fredoka(fontSize: 15, color: AdyapanTheme.green, fontWeight: FontWeight.w700)),
              ]
            ]),
          ),
          const SizedBox(height: 16),
        ],

        // Letter Assembly Tray
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AdyapanTheme.bgLightDark,
            border: Border.all(color: _unscrambleCompleted ? AdyapanTheme.green : AdyapanTheme.glassBorder, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: _tappedLetterIndices.isEmpty
              ? Center(child: Text('Tap letters below to spell!', style: AdyapanTheme.outfit(fontSize: 11, color: AdyapanTheme.textMuted)))
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.start,
                  children: _tappedLetterIndices.map((idx) {
                    return GestureDetector(
                      onTap: _unscrambleCompleted ? null : () => setState(() => _tappedLetterIndices.remove(idx)),
                      child: Container(
                        width: 38,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: _unscrambleCompleted
                            ? [AdyapanTheme.green, const Color(0xFF059669)]
                            : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          scrambled[idx],
                          style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 20),

        Text('Scrambled Letter Blocks:', style: AdyapanTheme.outfit(fontSize: 13, color: AdyapanTheme.textSub, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: List.generate(scrambled.length, (idx) {
            bool isUsed = _tappedLetterIndices.contains(idx);
            return GestureDetector(
              onTap: isUsed || _unscrambleCompleted ? null : () => setState(() => _tappedLetterIndices.add(idx)),
              child: Opacity(
                opacity: isUsed ? 0.25 : 1.0,
                child: Container(
                  width: 42,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: isUsed ? AdyapanTheme.glassBorder : const Color(0xFF8B5CF6).withOpacity(0.4),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isUsed ? [] : const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Text(
                    scrambled[idx],
                    style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF3B1D8B)),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        if (outOfChances)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AdyapanTheme.pink.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AdyapanTheme.pink),
              const SizedBox(width: 8),
              Expanded(child: Text('No more attempts! See the answer above.', style: AdyapanTheme.fredoka(color: AdyapanTheme.pink, fontWeight: FontWeight.bold))),
            ]),
          ),

        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _tappedLetterIndices.isEmpty || _unscrambleCompleted ? null : () => setState(() => _tappedLetterIndices.clear()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
                  side: const BorderSide(color: AdyapanTheme.glassBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: Text('Reset', style: AdyapanTheme.fredoka(color: AdyapanTheme.textSub)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (_tappedLetterIndices.isEmpty || _unscrambleCompleted || outOfChances) ? null : () {
                  final assembledWord = _tappedLetterIndices.map((idx) => scrambled[idx]).join().toUpperCase();
                  if (assembledWord == targetWord) {
                    _triggerWin();
                    setState(() => _unscrambleCompleted = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('🎉 Correct! You unscrambled "$targetWord"!'), backgroundColor: AdyapanTheme.green),
                    );
                  } else {
                    setState(() { _unscrambleWrongTaps++; _tappedLetterIndices.clear(); });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Wrong! ${maxWrong - _unscrambleWrongTaps} attempts left.'), backgroundColor: AdyapanTheme.pink),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdyapanTheme.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: Text('Check Word ✓', style: AdyapanTheme.fredoka(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
        if (_unscrambleCompleted) ...[
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _tappedLetterIndices.clear(); _unscrambleCompleted = false;
                  _unscrambleWrongTaps = 0; _unscrambleShowHint = false; _unscrambleHintsUsed = 0;
                  if (_currentUnscrambleLevel + 1 < levels.length) _currentUnscrambleLevel++;
                  else _currentUnscrambleLevel = 0;
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdyapanTheme.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
              child: Text(
                _currentUnscrambleLevel + 1 < levels.length ? 'Next Level ▶' : '🔄 Restart Brain Booster',
                style: AdyapanTheme.fredoka(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ]
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdyapanTheme.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Arcade Banner Header
                Container(
                  padding: const EdgeInsets.only(top: 20, left: 12, right: 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu_rounded, color: AdyapanTheme.textMain, size: 24),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AdyapanTheme.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.sports_esports_rounded, color: AdyapanTheme.blueAccent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Arcade Console', style: AdyapanTheme.fredoka(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Level up your wisdom points!', style: AdyapanTheme.outfit(fontSize: 12, color: AdyapanTheme.textSub)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3D Glassmorphic Class Selector Bar (Class 1 to 12)
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _classes.length,
                    itemBuilder: (context, index) {
                      final cls = _classes[index];
                      final isSelected = cls == _selectedClass;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedClass = cls;
                              _assembledSyntax.clear();
                              _currentUnscrambleLevel = 0;
                              _tappedLetterIndices.clear();
                              _unscrambleCompleted = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)])
                                  : LinearGradient(colors: [Colors.white.withOpacity(0.65), Colors.white.withOpacity(0.45)]),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.white.withOpacity(0.5) : const Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected ? const Color(0xFF2563EB).withOpacity(0.3) : Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              cls,
                              style: GoogleFonts.fredoka(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Arcade Custom Navigation Tabs
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicator: BoxDecoration(
                      gradient: AdyapanTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AdyapanTheme.textSub,
                    labelStyle: AdyapanTheme.fredoka(fontSize: 11, fontWeight: FontWeight.bold),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Quiz Arena'),
                      Tab(text: 'Cognitive Arena'),
                      Tab(text: 'Syntax Block'),
                      Tab(text: 'Unscramble'),
                    ],
                  ),
                ),

                // Arcade Tab Content View
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      SingleChildScrollView(padding: const EdgeInsets.all(20), child: _buildQuizArena()),
                      SingleChildScrollView(padding: const EdgeInsets.all(20), child: _buildCognitiveLogicArena()),
                      SingleChildScrollView(padding: const EdgeInsets.all(20), child: _buildSyntaxBlocks()),
                      SingleChildScrollView(padding: const EdgeInsets.all(20), child: _buildWordUnscramble()),
                    ],
                  ),
                )
              ],
            ),

            // Embedded Confetti Overlay on top!
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [AdyapanTheme.blueAccent, AdyapanTheme.cyan, AdyapanTheme.green, AdyapanTheme.purple],
              ),
            )
          ],
        ),
      ),
    );
  }
}
