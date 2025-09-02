import 'package:flutter/material.dart';

class BookingView extends StatelessWidget {
  const BookingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {},
          child: const Text('Confirm Booking'),
        ),
      ),
    );
  }
}

