// lib/screens/luna_main_scaffold.dart

import 'package:flutter/material.dart';
import 'chat_page.dart';           
import 'mode_directory_page.dart'; // [확인] 이 파일이 lib/screens/ 안에 있어야 함

class LunaMainScaffold extends StatefulWidget {
  const LunaMainScaffold({super.key});

  @override
  State<LunaMainScaffold> createState() => _LunaMainScaffoldState();
}

class _LunaMainScaffoldState extends State<LunaMainScaffold> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: [
          // 1페이지: 채팅
          ChatPage(
            onNavigateToAssistant: () {
              _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            },
          ),
          
          // 2페이지: 디렉터리 (3대장 -> 8대메뉴)
          const ModeDirectoryPage(),
        ],
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
        selectedItemColor: Colors.blueGrey[800],
        unselectedItemColor: Colors.grey[400],
        showSelectedLabels: true,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Directory'),
        ],
      ),
    );
  }
}