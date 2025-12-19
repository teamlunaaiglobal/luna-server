import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class ToolSignatureScreen extends StatefulWidget {
  const ToolSignatureScreen({super.key});

  @override
  State<ToolSignatureScreen> createState() => _ToolSignatureScreenState();
}

class _ToolSignatureScreenState extends State<ToolSignatureScreen> {
  // 서명 컨트롤러
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("전자 서명 생성"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              if (_controller.isNotEmpty) {
                // 1. 이미지 변환 (대기)
                final signature = await _controller.toPngBytes();

                // 2. [★ 해결 핵심] 
                // mounted 대신 'context.mounted'를 써야 검사기가 인정합니다.
                // "이 context가 아직 살아있는가?"를 직접 묻는 코드입니다.
                if (!context.mounted) return;

                // 3. 이제 안전하게 사용 가능
                if (signature != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("서명이 클립보드에 저장되었습니다.")),
                  );
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: Signature(
                controller: _controller,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("손가락으로 서명하세요", style: TextStyle(color: Colors.grey)),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.red),
                  onPressed: () => _controller.clear(),
                  tooltip: "지우기",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}