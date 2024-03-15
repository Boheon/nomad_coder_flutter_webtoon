import 'dart:async';

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int totalSeconds = 10;
  int temp = 1500;
  bool isRunning = false;
  List<int> timerTime = [2, 20 * 60, 25 * 60, 30 * 60, 35 * 60];
  int totalCycle = 0;
  int totalRound = 0;
  late Timer timer;

  void onTick(Timer timer) {
    if (totalSeconds == 0) {
      setState(() {
        if (totalCycle == 4) {
          totalRound = totalRound + 1;
          breakTime();
          totalCycle = 0;
          //totalSeconds = temp;
        } else {
          totalCycle = totalCycle + 1;
          totalSeconds = temp;
        }
      });
    } else {
      setState(() {
        totalSeconds = totalSeconds - 1;
      });
    }
  }

  void onStartPressed() {
    timer = Timer.periodic(
      const Duration(seconds: 1),
      onTick,
    );
    setState(() {
      isRunning = true;
    });
  }

  void onPausePressed() {
    timer.cancel();
    setState(() {
      isRunning = false;
    });
  }

  void onRestartPressed() {
    if (isRunning) timer.cancel();
    setState(() {
      totalCycle = 0;
      totalRound = 0;
      totalSeconds = temp;
      isRunning = false;
    });
  }

  void chooseTime(int a) {
    if (isRunning) timer.cancel();
    setState(() {
      temp = timerTime[a];
      totalSeconds = temp;
      isRunning = false;
    });
  }

  void breakTime() {
    setState(() {
      totalSeconds = 7;
    });
  }

  String format(int seconds) {
    var duration = Duration(seconds: seconds);
    return duration.toString().split(".").first.substring(2, 7);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          Flexible(
            flex: 1,
            child: Container(
              alignment: Alignment.centerLeft,
              child: Text(
                'POMOTIMER',
                style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Flexible(
            flex: 3,
            child: Center(
              child: Column(
                children: [
                  Text(
                    format(totalSeconds),
                    style: TextStyle(
                      color: Theme.of(context).cardColor,
                      fontSize: 89,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        onPressed: () => chooseTime(0),
                        child: Text(
                          '15',
                          style: TextStyle(color: Theme.of(context).cardColor),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => chooseTime(1),
                        child: Text(
                          '20',
                          style: TextStyle(color: Theme.of(context).cardColor),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => chooseTime(2),
                        child: Text(
                          '25',
                          style: TextStyle(color: Theme.of(context).cardColor),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => chooseTime(3),
                        child: Text(
                          '30',
                          style: TextStyle(color: Theme.of(context).cardColor),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => chooseTime(4),
                        child: Text(
                          '35',
                          style: TextStyle(color: Theme.of(context).cardColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 120,
                        color: Theme.of(context).cardColor,
                        onPressed: isRunning ? onPausePressed : onStartPressed,
                        icon: Icon(isRunning
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline),
                      ),
                      IconButton(
                          iconSize: 120,
                          color: Theme.of(context).cardColor,
                          onPressed: onRestartPressed,
                          icon: const Icon(Icons.restart_alt_outlined)),
                    ],
                  )
                ],
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      '$totalCycle/4',
                      style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontSize: 35,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'ROUND',
                      style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontSize: 35,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '$totalRound/12',
                      style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontSize: 35,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'GOAL',
                      style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontSize: 35,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
