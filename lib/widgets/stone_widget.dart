import 'package:flutter/material.dart';
import 'dart:math';
import '../models/okey_stone.dart';

class StoneFlipWrapper extends StatelessWidget {
  final OkeyStone stone;
  const StoneFlipWrapper({required this.stone, super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: stone.isRevealed ? pi : 0),
      builder: (context, double angle, child) {
        final isFront = angle > pi / 2;
        return Transform(
          transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
          alignment: Alignment.center,
          child: isFront 
            ? Transform(transform: Matrix4.rotationY(pi), alignment: Alignment.center, child: StoneBody3D(stone: stone, forceReveal: true))
            : StoneBody3D(stone: stone, forceReveal: false),
        );
      },
    );
  }
}

class StoneBody3D extends StatelessWidget {
  final OkeyStone stone;
  final bool? forceReveal;
  const StoneBody3D({required this.stone, this.forceReveal, super.key});

  @override
  Widget build(BuildContext context) {
    bool isVisible = forceReveal ?? stone.isRevealed;
    return Center(
      child: SizedBox(
        width: 48, height: 68,
        child: Stack(
          children: [
            Container(margin: const EdgeInsets.only(top: 4, left: 2), decoration: BoxDecoration(color: const Color(0xFFC8C8B5), borderRadius: BorderRadius.circular(4))),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFFDFDFB), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white, width: 0.5), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(-1, -1))]),
              child: ClipRRect(borderRadius: BorderRadius.circular(4), child: isVisible ? Image.asset(stone.path, fit: BoxFit.contain) : Image.asset('assets/images/tas_arka.png', fit: BoxFit.contain)),
            ),
          ],
        ),
      ),
    );
  }
}