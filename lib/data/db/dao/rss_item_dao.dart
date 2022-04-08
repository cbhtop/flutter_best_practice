import 'package:drift/drift.dart';
import 'package:flutter_best_practice/data/db/table/rss_item_table.dart';
import 'package:flutter_best_practice/data/model/rss_category.dart';
import 'package:flutter_best_practice/data/model/rss_item_model.dart';

import '../rss_db.dart';

part 'rss_item_dao.g.dart';

extension RssItemTableDataExt on RssItemTableData {
  RssItemModel toRssItemModel() {
    return RssItemModel(
      id: id,
      fid: fid,
      cateId: cateId,
      title: title,
      desc: desc,
      link: link,
      author: author,
      pubDate: pubDate,
      content: content,
      isCached: isCached,
      isRead: isRead,
      cover: cover,
      category: category,
      rssLogo: rssLogo,
      rssName: rssName,
    );
  }
}

@DriftAccessor(tables: [RssItemTable])
class RssItemDao extends DatabaseAccessor<RssDatabase> with _$RssItemDaoMixin {
  RssItemDao(RssDatabase attachedDatabase) : super(attachedDatabase);

  /// 获取列表, 按时间排序
  Future<List<RssItemModel>> fetchItems(
      {required int page, required int pageSize}) async {
    final res = await (select(rssItemTable)
          ..orderBy([
            (t) => OrderingTerm(expression: t.pubDate, mode: OrderingMode.asc)
          ])
          ..limit(pageSize, offset: (page - 1) * pageSize))
        .get();

    return res.map((e) => e.toRssItemModel()).toList();
  }

  /// 保存多个
  Future<List<int>> saveItems(List<RssItemModel> items) async {
    final futures = items.map((element) async {
      var res = await (select(rssItemTable)
            ..where((tbl) =>
                tbl.fid.equals(element.fid) & tbl.title.equals(element.title)))
          .getSingleOrNull();
      if (res == null) {
        /// 不存在则，进行保存
        final res = await addItem(element);
        return res;
      } else {
        res = res.copyWith(
          title: element.title,
          category: element.category,
          link: element.link,
          author: element.author,
          cover: element.cover,
          desc: element.desc,
          content: element.content,
          pubDate: element.pubDate,
          cateId: element.cateId,
          rssLogo: element.rssLogo,
          rssName: element.rssName,
        );
        await update(rssItemTable).replace(res);
        return res.id;
      }
    });
    return await Future.wait(futures);
  }

  Future<int> addItem(RssItemModel item) async {
    return into(rssItemTable).insert(
      RssItemTableCompanion(
        fid: Value(item.fid),
        cateId: Value(item.cateId),
        title: Value(item.title),
        desc: Value(item.desc),
        content: Value(item.content),
        link: Value(item.link),
        author: Value(item.author),
        pubDate: Value(item.pubDate),
        category: Value(item.category),
        cover: Value(item.cover),
        isRead: Value(item.isRead),
        isCached: Value(item.isCached),
        rssName: Value(item.rssName),
        rssLogo: Value(item.rssLogo),
      ),
    );
  }

  /// 获取某个rss的items
  Future<List<RssItemModel>> getItems(int fid) async {
    final res = await (select(rssItemTable)
          ..where((tbl) => tbl.fid.equals(fid))
          ..orderBy([
            (t) => OrderingTerm(expression: t.pubDate, mode: OrderingMode.desc)
          ]))
        .get();

    return res.map((e) => e.toRssItemModel()).toList();
  }

  /// 删除某个rss的items
  Future<int> deleteItemsFromRss(int fid) {
    return (delete(rssItemTable)..where((tbl) => tbl.fid.equals(fid))).go();
  }

  resetCateId(int oldCateId) async {
    return (update(rssItemTable)..where((tbl) => tbl.cateId.equals(oldCateId)))
        .write(const RssItemTableCompanion(cateId: Value(0)));
  }

  updateRssItemToCate(List<int> rssIds, RssCategory cate) async {
    return (update(rssItemTable)..where((tbl) => tbl.fid.isIn(rssIds)))
        .write(RssItemTableCompanion(cateId: Value(cate.id)));
  }

  /// 更新某个item
  Future<int> updateRssItem(RssItemModel item) async {
    return (update(rssItemTable)..where((tbl) => tbl.id.equals(item.id))).write(
      RssItemTableCompanion(
        fid: Value(item.fid),
        cateId: Value(item.cateId),
        title: Value(item.title),
        desc: Value(item.desc),
        content: Value(item.content),
        link: Value(item.link),
        author: Value(item.author),
        pubDate: Value(item.pubDate),
        category: Value(item.category),
        cover: Value(item.cover),
        isRead: Value(item.isRead),
        isCached: Value(item.isCached),
        rssName: Value(item.rssName),
        rssLogo: Value(item.rssLogo),
      ),
    );
  }
}
