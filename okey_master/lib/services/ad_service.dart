import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'connectivity_service.dart';

enum RewardType { extraTime, hint, passTurn }

enum RewardResult { success, dismissed, noConnection, notLoaded, error, timeout }

class AdService {
  final ConnectivityService _connectivity;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  // Test ID'leri. Gerçek yayın öncesi AdMob Console'dan alınan ID'lerle değiştirilecek.
  static const _rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  AdService(this._connectivity) {
    _initAdMob();
  }

  Future<void> _initAdMob() async {
    await MobileAds.instance.initialize();
    loadRewardedAd();
  }

  Future<void> loadRewardedAd() async {
    if (_isRewardedAdLoading || _rewardedAd != null) return;
    if (!(await _connectivity.isOnline)) return; // Offline ise yükleme

    _isRewardedAdLoading = true;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoading = false;
        },
      ),
    );
  }

  Future<RewardResult> showRewardedAd() async {
    if (!(await _connectivity.isOnline)) return RewardResult.noConnection;
    if (_rewardedAd == null) {
      loadRewardedAd(); // Yeniden yüklemeyi dene
      return RewardResult.notLoaded;
    }

    final completer = Completer<RewardResult>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {},
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // Sonrakini hazırla
        if (!completer.isCompleted) completer.complete(RewardResult.dismissed);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete(RewardResult.error);
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      if (!completer.isCompleted) completer.complete(RewardResult.success);
    });

    return completer.future.timeout(
      const Duration(seconds: 45), 
      onTimeout: () => RewardResult.timeout
    );
  }
}
