import 'package:flutter_best_practice/data/db/dao/rss_dao.dart';
import 'package:flutter_best_practice/data/db/dao/rss_item_dao.dart';
import 'package:flutter_best_practice/data/repository/rss_repository.dart';
import '../data/model/rss_item_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../provider.dart';
import '../data/model/rss.dart';

class RssArticlesState {
  final Rss rss;

  RssArticlesState({required this.rss});

  RssArticlesState.initial(this.rss);

  RssArticlesState copy({Rss? rss}) {
    return RssArticlesState(rss: rss ?? this.rss);
  }
}

class RssArticlesNotifier extends StateNotifier<RssArticlesState> {
  final RssDao rssDao;
  final RssItemDao rssItemDao;
  final IRssRepository rssRepository;

  RssArticlesNotifier(
    Rss rss, {
    required this.rssDao,
    required this.rssRepository,
    required this.rssItemDao,
  }) : super(RssArticlesState.initial(rss));

  readRssItem(RssItemModel item) {
    final newItem = item.copy(isRead: true);
    final rss = state.rss;
    int itemIndex = rss.rssItems.indexWhere((element) => element.id == item.id);
    if (itemIndex >= 0) {
      rss.rssItems[itemIndex] = newItem;
    }
    state = state.copy(rss: rss);
  }

  // 下拉刷新
  onRefresh(RefreshController controller) async {
    // 需要更新 rss
    final rss =
        await rssRepository.getRss(state.rss.feedUrl, type: state.rss.type);
    if (rss != null) {
      rss.id = state.rss.id;
      await rssDao.saveRss(rss, rssItemDao: rssItemDao);
      state = state.copy(rss: rss);
    }
    controller.refreshCompleted();
  }
}

final rssArticlesProvider = StateNotifierProvider.autoDispose
    .family<RssArticlesNotifier, RssArticlesState, Rss>((ref, rss) {
  final rssDao = ref.watch(rssDaoProvider);
  final resp = ref.watch(repositoryProvider);
  final rssItemDao = ref.watch(rssItemDaoProvider);
  return RssArticlesNotifier(rss,
      rssDao: rssDao, rssRepository: resp, rssItemDao: rssItemDao);
});
