import 'package:flutter/material.dart';
import 'package:health_pet/functions/google_ads.dart';

class GoogleAdsProvider with ChangeNotifier {
  final GoogleAds _googleAds = GoogleAds();
  bool _isBannerLoaded = false;
  bool _isInterstitialLoaded = false;

  // Getter'lar
  bool get isBannerLoaded => _isBannerLoaded;
  bool get isInterstitialLoaded => _isInterstitialLoaded;
  GoogleAds get googleAds => _googleAds;

  // Banner yükleme
  Future<void> loadBannerAd() async {
    _googleAds.loadBannerAd();
    _isBannerLoaded = true;
    notifyListeners();
  }

  // Interstitial yükleme
  Future<void> loadInterstitialAd() async {
    _googleAds.loadInterstitialAd();
    _isInterstitialLoaded = true;
    notifyListeners();
  }

  // Interstitial gösterme
  void showInterstitialAd() {
    if (_isInterstitialLoaded) {
      _googleAds.showInterstitialAd();
      _isInterstitialLoaded = false;
      notifyListeners();
      // Sonraki reklamı önceden yükle
      loadInterstitialAd();
    }
  }

  @override
  void dispose() {
    _googleAds.dispose();
    super.dispose();
  }
}
