import 'package:flutter/material.dart';

class StatisticsServiceWidget extends StatelessWidget {
  const StatisticsServiceWidget({
    super.key,
    required this.ssUrl,
    required this.ssStatus,
    required this.ssStatusColor,
  });

  final String ssUrl;
  final String ssStatus;
  final Color ssStatusColor;

  @override
  Widget build(BuildContext context) {
    // デバイスの横幅を取得する
    double screenWidth = MediaQuery.of(context).size.width;

    return Row(
      children: [
        Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: screenWidth - (const EdgeInsets.all(10.0).left * 3),
              minHeight: 32.0,
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Statistics Service: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    TextSpan(
                      text: '$ssUrl\n',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    TextSpan(
                      text: 'Server Status: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    TextSpan(
                      text: ssStatus,
                      style: TextStyle(
                        color: ssStatusColor,
                      ),
                    ),
                  ],
                ),
                overflow: TextOverflow.fade,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
