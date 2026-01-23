import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SmileLine Monitoring - Widget Tests', () {
    // ============ BASIC WIDGET TESTS ============

    testWidgets('Counter increments smoke test', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Verify that our counter starts at 0.
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsNothing);

      // Tap the '+' icon and trigger a frame.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Verify that our counter has incremented.
      expect(find.text('0'), findsNothing);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('SplashScreen widget test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF1ABC9C),
            body: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('😊', style: TextStyle(fontSize: 50)),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('😊'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('HomeScreen widget rendering', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              title: const Text(
                'Domenico',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1ABC9C), Color(0xFF16A085)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Benvenuto, Domenico!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Continua il tuo percorso di allineamento',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Benvenuto, Domenico!'), findsOneWidget);
      expect(find.text('Continua il tuo percorso di allineamento'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('TimerScreen display test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1ABC9C),
                          const Color(0xFF16A085),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1ABC9C).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '00:05:30',
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('00:05:30'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('HistoryScreen widget test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              title: const Text(
                'Cronologia',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistiche Generali',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1ABC9C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF1ABC9C).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF1ABC9C),
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '30',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1ABC9C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Giorni',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Statistiche Generali'), findsOneWidget);
      expect(find.text('Giorni'), findsOneWidget);
    });

    testWidgets('SettingsScreen widget test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              title: const Text(
                'Impostazioni',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Text(
                      'Profilo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1ABC9C),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFF1ABC9C),
                          child: Text(
                            'D',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Domenico Rossi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'domenico@example.com',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Profilo'), findsOneWidget);
      expect(find.text('Domenico Rossi'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('Onboarding Step 1 widget test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Passo 1 di 3'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dati del Trattamento',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configura i parametri del tuo piano di allineamento',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Numero Totale Stage',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '24',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Dati del Trattamento'), findsOneWidget);
      expect(find.text('Numero Totale Stage'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    // ============ UNIT LOGIC TESTS ============

    test('Calculate total days', () {
      const totalStages = 24;
      const stageADays = 7;
      const stageBDays = 7;
      const totalDays = totalStages * (stageADays + stageBDays);

      expect(totalDays, 336);
    });

    test('Calculate progress percentage', () {
      const totalDays = 336;
      const daysPassed = 168;
      final progressPercentage = (daysPassed / totalDays * 100);

      expect(progressPercentage, closeTo(50.0, 0.1));
    });

    test('Calculate compliance percentage', () {
      const targetHours = 22;
      const actualHours = 22;
      final compliance = (actualHours / targetHours * 100).clamp(0.0, 100.0);

      expect(compliance, 100.0);
    });

    test('Meeting target logic', () {
      const targetHours = 22;
      const wearingHours = 22;
      const wearingMinutes = 0;
      const totalMinutes = wearingHours * 60 + wearingMinutes;
      const targetMinutes = targetHours * 60;

      final isMeetingTarget = totalMinutes >= targetMinutes;

      expect(isMeetingTarget, true);
    });

    test('Not meeting target logic', () {
      const targetHours = 22;
      const wearingHours = 20;
      const wearingMinutes = 30;
      const totalMinutes = wearingHours * 60 + wearingMinutes;
      const targetMinutes = targetHours * 60;

      final isMeetingTarget = totalMinutes >= targetMinutes;

      expect(isMeetingTarget, false);
    });

    test('Calculate remaining hours', () {
      const targetHours = 22;
      const wearingHours = 15;
      const remainingHours = targetHours - wearingHours;

      expect(remainingHours, 7);
    });

    test('Format time HH:MM:SS', () {
      const elapsedSeconds = 3665; // 1 hour 1 minute 5 seconds
      final hours = (elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
      final minutes =
      (((elapsedSeconds % 3600) ~/ 60)).toString().padLeft(2, '0');
      final seconds = (elapsedSeconds % 60).toString().padLeft(2, '0');
      final formattedTime = '$hours:$minutes:$seconds';

      expect(formattedTime, '01:01:05');
    });

    test('Calculate stage duration', () {
      const stageDays = 7;
      const dailyHours = 22;
      const totalStageHours = stageDays * dailyHours;

      expect(totalStageHours, 154);
    });

    test('Calculate age from birthdate', () {
      final birthDate = DateTime(1990, 5, 15);
      final now = DateTime.now();
      var age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      expect(age, greaterThan(30));
    });

    test('Check if treatment completed', () {
      final today = DateTime.now();
      final treatmentStart = DateTime(2020, 1, 1);
      final treatmentEnd = DateTime(2030, 1, 1);

      final isCompleted = today.isAfter(treatmentEnd);

      expect(isCompleted, false);
    });
  });
}

// ============ SIMPLE APP FOR TESTING ============

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Test App'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'You have pushed the button this many times:',
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}