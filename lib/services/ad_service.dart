import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  InterstitialAd? _interstitialAd;
  final String _adUnitId = Platform.isAndroid ? 'ca-app-pub-3940256099942544/1033173712' : 'ca-app-pub-3940256099942544/4411468910';

  void loadAd() {
    InterstitialAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) { _interstitialAd = ad; },
          onAdFailedToLoad: (error) { _interstitialAd = null; },
        ));
  }

  void showAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) { ad.dispose(); loadAd(); },
        onAdFailedToShowFullScreenContent: (ad, err) { ad.dispose(); loadAd(); }
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } else { loadAd(); }
  }
}