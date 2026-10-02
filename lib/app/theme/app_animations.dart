import 'package:flutter/material.dart';

const shortAnimation = Duration(milliseconds: 200);
const mediumAnimation = Duration(milliseconds: 350);
const longAnimation = Duration(milliseconds: 500);

const defaultCurve = Curves.easeInOut;
const springCurve = Curves.elasticOut;

Duration animationDuration(bool reduced, {Duration normal = mediumAnimation}) {
  return reduced ? Duration.zero : normal;
}

Curve animationCurve(bool reduced) {
  return reduced ? Curves.linear : defaultCurve;
}
