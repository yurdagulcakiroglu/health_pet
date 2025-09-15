import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:health_pet/utils/ad_strings.dart';

class GoogleAds {
  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;
  bool _isInterstitialLoading = false;
  bool _isBannerLoading = false;

  final String interstitialAdId;
  final String bannerAdId;

  GoogleAds({
    this.interstitialAdId = KAdStrings.interstitialAd1,
    this.bannerAdId = KAdStrings.bannerAd1,
  });

  void loadInterstitialAd({bool showAfterLoad = false, int retryCount = 0}) {
    if (_isInterstitialLoading) return;

    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _isInterstitialLoading = false;
          debugPrint('Ad was loaded.');
          _interstitialAd = ad;

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (InterstitialAd ad) {
                  debugPrint('Ad dismissed.');
                  ad.dispose();
                  _interstitialAd = null;
                  loadInterstitialAd(); // Preload next ad
                },
                onAdFailedToShowFullScreenContent:
                    (InterstitialAd ad, AdError error) {
                      debugPrint('Ad failed to show: $error');
                      ad.dispose();
                      _interstitialAd = null;
                    },
              );

          if (showAfterLoad) showInterstitialAd();
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isInterstitialLoading = false;
          debugPrint('Ad failed to load: $error');
          _interstitialAd = null;

          // Retry logic with exponential backoff
          if (retryCount < 3) {
            Future.delayed(Duration(seconds: 1 * (retryCount + 1)), () {
              loadInterstitialAd(
                showAfterLoad: showAfterLoad,
                retryCount: retryCount + 1,
              );
            });
          }
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      debugPrint('Interstitial ad is not loaded yet. Loading now...');
      loadInterstitialAd(showAfterLoad: true);
    }
  }

  Widget getBannerAdWidget({double height = AdSize.banner.height.toDouble()}) {
    if (_bannerAd == null) {
      loadBannerAd();
      return SizedBox(height: height);
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  void loadBannerAd({int retryCount = 0}) {
    if (_isBannerLoading) return;

    _isBannerLoading = true;

    _bannerAd = BannerAd(
      adUnitId: bannerAdId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerLoading = false;
          _bannerAd = ad as BannerAd;
          debugPrint('Banner ad loaded.');
        },
        onAdFailedToLoad: (ad, err) {
          _isBannerLoading = false;
          debugPrint("Banner ad failed to load: $err");
          ad.dispose();
          _bannerAd = null;

          // Retry logic
          if (retryCount < 3) {
            Future.delayed(Duration(seconds: 1 * (retryCount + 1)), () {
              loadBannerAd(retryCount: retryCount + 1);
            });
          }
        },
      ),
    )..load();
  }

  void dispose() {
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    _interstitialAd = null;
    _bannerAd = null;
  }
}
