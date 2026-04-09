 import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ShufflingCounter extends StatefulWidget {
  final String targetValue;
  final bool isLoading;
  final TextStyle? textStyle;
  final Duration shuffleDuration;

  const ShufflingCounter({
    super.key,
    required this.targetValue,
    required this.isLoading,
    this.textStyle,
    this.shuffleDuration = const Duration(milliseconds: 50),
  });

  @override
  State<ShufflingCounter> createState() => _ShufflingCounterState();
}

class _ShufflingCounterState extends State<ShufflingCounter> {
  late String _displayValue;
  Timer? _shuffleTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _displayValue = widget.isLoading ? _generateRandomNumber() : widget.targetValue;
    if (widget.isLoading) {
      _startShuffling();
    }
  }

  @override
  void didUpdateWidget(ShufflingCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isLoading && !oldWidget.isLoading) {
      // Started loading - begin shuffling
      _startShuffling();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      // Finished loading - stop shuffling and show actual value
      _stopShuffling();
      _animateToTarget();
    } else if (!widget.isLoading) {
      // Not loading - just update value
      _displayValue = widget.targetValue;
    }
  }

  void _startShuffling() {
    _shuffleTimer?.cancel();
    _shuffleTimer = Timer.periodic(widget.shuffleDuration, (timer) {
      if (mounted) {
        setState(() {
          _displayValue = _generateRandomNumber();
        });
      }
    });
  }

  void _stopShuffling() {
    _shuffleTimer?.cancel();
    _shuffleTimer = null;
  }

  String _generateRandomNumber() {
    // Generate a random number with similar digit length to make it look realistic
    int digits = widget.targetValue.isNotEmpty ? widget.targetValue.length : 2;
    digits = digits.clamp(1, 4); // Keep between 1-4 digits for aesthetics
    
    int min = pow(10, digits - 1).toInt();
    int max = pow(10, digits).toInt() - 1;
    
    if (digits == 1) {
      min = 0;
      max = 9;
    }
    
    return (_random.nextInt(max - min + 1) + min).toString();
  }

  void _animateToTarget() {
    // Quick animation effect before showing final value
    int steps = 5;
    int currentStep = 0;
    
    Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (currentStep >= steps || !mounted) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _displayValue = widget.targetValue;
          });
        }
        return;
      }
      
      setState(() {
        _displayValue = _generateRandomNumber();
      });
      currentStep++;
    });
  }

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(
        _displayValue,
        key: ValueKey<String>(_displayValue),
        style: widget.textStyle,
      ),
    );
  }
}

/// A widget for shuffling text (non-numeric) like credits
class ShufflingText extends StatefulWidget {
  final String targetValue;
  final bool isLoading;
  final TextStyle? textStyle;
  final Duration shuffleDuration;

  const ShufflingText({
    super.key,
    required this.targetValue,
    required this.isLoading,
    this.textStyle,
    this.shuffleDuration = const Duration(milliseconds: 50),
  });

  @override
  State<ShufflingText> createState() => _ShufflingTextState();
}

class _ShufflingTextState extends State<ShufflingText> {
  late String _displayValue;
  Timer? _shuffleTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _displayValue = widget.isLoading ? _generateRandomNumber() : widget.targetValue;
    if (widget.isLoading) {
      _startShuffling();
    }
  }

  @override
  void didUpdateWidget(ShufflingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isLoading && !oldWidget.isLoading) {
      _startShuffling();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _stopShuffling();
      _animateToTarget();
    } else if (!widget.isLoading) {
      _displayValue = widget.targetValue;
    }
  }

  void _startShuffling() {
    _shuffleTimer?.cancel();
    _shuffleTimer = Timer.periodic(widget.shuffleDuration, (timer) {
      if (mounted) {
        setState(() {
          _displayValue = _generateRandomNumber();
        });
      }
    });
  }

  void _stopShuffling() {
    _shuffleTimer?.cancel();
    _shuffleTimer = null;
  }

  String _generateRandomNumber() {
    int min = 10;
    int max = 999;
    return (_random.nextInt(max - min + 1) + min).toString();
  }

  void _animateToTarget() {
    int steps = 5;
    int currentStep = 0;
    
    Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (currentStep >= steps || !mounted) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _displayValue = widget.targetValue;
          });
        }
        return;
      }
      
      setState(() {
        _displayValue = _generateRandomNumber();
      });
      currentStep++;
    });
  }

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayValue,
      style: widget.textStyle,
    );
  }
}


