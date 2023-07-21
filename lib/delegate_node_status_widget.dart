import 'package:flutter/material.dart';

import 'main.dart';

class DelegateNodeStatusWidget extends StatefulWidget {
  const DelegateNodeStatusWidget({
    super.key,
    required this.isStatisticsServiceActive,
    required this.statisticsServiceJson,
  });

  final bool isStatisticsServiceActive;
  final List<dynamic> statisticsServiceJson;

  @override
  State<DelegateNodeStatusWidget> createState() => DelegateNodeStatusState();
}

class DelegateNodeStatusState extends State<DelegateNodeStatusWidget> {
  DelegateNodeStatus delegateStat = DelegateNodeStatus();

  void setDelegateNodeStatus(DelegateNodeStatus delegateStat) {
    setState(() {
      this.delegateStat = delegateStat;
    });
  }

  @override
  Widget build(BuildContext context) {
    // デバイスの横幅を取得する
    double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(0),
      child: Row(children: [
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
                      text: 'Delegate Node Info\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    TextSpan(
                      text: 'Host: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    TextSpan(
                      text: '${delegateStat.host}\n',
                      style: TextStyle(
                        color: delegateStat.isErrHost
                            ? Colors.red
                            : Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    TextSpan(
                      text: 'Friendly Name: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    TextSpan(
                      text: '${delegateStat.friendlyName}\n',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    TextSpan(
                      text: 'Cert Exp: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    TextSpan(
                      text: '${delegateStat.certExp}\n',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    TextSpan(
                      text: 'Node Health(Api/DB): ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    TextSpan(
                      text: '${delegateStat.nodeHealth}\n',
                      style: TextStyle(
                        color:
                            delegateStat.isErrHost ? Colors.red : Colors.green,
                      ),
                    ),
                    TextSpan(
                      text: 'Delegation Status: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    TextSpan(
                      text: delegateStat.delegateStatus,
                      style: TextStyle(
                        color: delegateStat.isErrDelegateStatus
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
                overflow: TextOverflow.fade,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
