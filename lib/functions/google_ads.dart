import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:health_pet/utils/ad_strings.dart';

class GoogleAds {
  InterstitialAd? interstitialAd;
  BannerAd? bannerAd;

  void loadInterstitialAd({bool showAfterLoad = false}) {
    InterstitialAd.load(
      adUnitId: KAdStrings.interstitialAd1, // Test ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('Ad was loaded.');
          interstitialAd = ad;

          // Reklam kapatıldığında dispose et
          interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              debugPrint('Ad dismissed.');
              ad.dispose();
              interstitialAd = null;
              loadInterstitialAd(); // İstersen tekrar yükleyebilirsin
            },
            onAdFailedToShowFullScreenContent:
                (InterstitialAd ad, AdError error) {
                  debugPrint('Ad failed to show: $error');
                  ad.dispose();
                  interstitialAd = null;
                },
          );

          if (showAfterLoad) showInterstitialAd();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Ad failed to load: $error');
          interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (interstitialAd != null) {
      interstitialAd!.show();
      interstitialAd = null;
    } else {
      debugPrint('Interstitial ad is not loaded yet.');
    }
  }

  void loadBannerAd() {
    bannerAd = BannerAd(
      adUnitId: KAdStrings.bannerAd1, // Test ID
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          bannerAd = ad as BannerAd;
          debugPrint('$ad loaded.');
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint("Ad failed to load: $err");
          ad.dispose();
        },
      ),
    )..load();
  }
}
