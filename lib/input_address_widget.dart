import 'package:flutter/material.dart';

/// アドレス入力
class InputAddressWidget extends StatelessWidget {
  const InputAddressWidget({super.key, required this.notifySetStateAddress});

  final Function(String address) notifySetStateAddress;

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    return Padding(
      padding: const EdgeInsets.only(
        top: 10.0,
        right: 5.0,
        bottom: 10.0,
        left: 5.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Form(
              key: formKey,
              child: TextFormField(
                // 初期値
                // initialValue: inputAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'N...',
                  labelText: 'Address',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    // 未入力
                    return 'input address';
                  }
                  // 大文字化
                  String address = value.toUpperCase();
                  if (address[0] != 'N') {
                    // Nから始まっていない
                    return 'address starts with N';
                  }
                  // ハイフン除去
                  address = address.replaceAll('-', '');
                  // ハイフン除去後の長さ39文字
                  if (address.length < 39) {
                    // 短い
                    return 'short address';
                  } else if (address.length > 39) {
                    // 長い
                    return 'long address';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (formKey.currentState!.validate()) {
                    // valid通った場合
                    notifySetStateAddress(value.replaceAll('-', ''));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
