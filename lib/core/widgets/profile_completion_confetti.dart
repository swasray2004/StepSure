import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class ProfileCompletionConfetti extends StatefulWidget {
  final VoidCallback onDone;

  const ProfileCompletionConfetti({required this.onDone, super.key});

  @override
  State<ProfileCompletionConfetti> createState() =>
      _ProfileCompletionConfettiState();
}

class _ProfileCompletionConfettiState
    extends State<ProfileCompletionConfetti> {

  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _controller.play();

    Future.delayed(const Duration(seconds: 2), () {
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        Container(
          color: Colors.white.withOpacity(0.9),
        ),

        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.2,
          ),
        ),

        const Center(
          child: Text(
            "Profile Completed 🎉",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}