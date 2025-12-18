import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 광고 및 특수 행동 처리기 (Real AdMob Version)
class AdActionHandler {
  
  // [Test ID] 개발 및 테스트용 보상형 광고 ID
  static const String _adUnitId = 'ca-app-pub-3940256099942544/5224354917';

  static RewardedAd? _rewardedAd;
  static bool _isAdLoaded = false;

  /// 광고 미리 로드
  static Future<void> preloadAd() async {
    await RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('💰 [AdMob] 광고 로드 성공!');
          _rewardedAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('⚠️ [AdMob] 광고 로드 실패: ${error.message}');
          _isAdLoaded = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  /// 광고 실행 (사용자에게 보여줌)
  static Future<void> perform(String message) async {
    debugPrint("🎬 Action Triggered: $message");

    // 1. 로드 안 됐으면 긴급 로드
    if (!_isAdLoaded || _rewardedAd == null) {
      debugPrint("⏳ 광고 로드 중...");
      await preloadAd();
      // 짧은 대기 (최대 2초)
      int retry = 0;
      while (!_isAdLoaded && retry < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        retry++;
      }
    }

    if (_rewardedAd == null) {
      debugPrint("❌ 광고 로드 실패. (네트워크 확인 필요)");
      return;
    }

    // 2. 광고 종료 대기를 위한 Completer
    final Completer<void> completer = Completer<void>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('📺 광고 닫힘');
        ad.dispose();
        preloadAd(); // 다음 광고 미리 장전
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('⚠️ 광고 표시 실패: $error');
        ad.dispose();
        preloadAd();
        if (!completer.isCompleted) completer.complete();
      },
    );

    // 3. 광고 송출
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
        debugPrint("🎁 [Reward] 보상 획득 확인!");
        // 여기서 함수가 끝나면 IntegratedService가 선물을 리필함
      },
    );

    await completer.future;
  }
}