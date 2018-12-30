import 'dart:async';
import 'dart:core';

import 'package:delern_flutter/models/base/database_list_event.dart';
import 'package:delern_flutter/models/base/enum.dart';
import 'package:delern_flutter/models/base/model.dart';
import 'package:delern_flutter/models/deck_access.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:meta/meta.dart';

enum DeckType { basic, german, swiss }

class DeckModel implements Model {
  String uid;
  String key;
  String name;
  bool markdown;
  DeckType type;
  bool accepted;
  AccessType access;
  DateTime lastSyncAt;
  String category;

  DeckModel({@required this.uid}) : assert(uid != null) {
    lastSyncAt = DateTime.fromMillisecondsSinceEpoch(0);
    markdown = false;
    type = DeckType.basic;
    accepted = true;
  }

  // We expect this to be called often and optimize for performance.
  DeckModel.copyFrom(DeckModel other)
      : uid = other.uid,
        key = other.key,
        name = other.name,
        markdown = other.markdown,
        type = other.type,
        accepted = other.accepted,
        lastSyncAt = other.lastSyncAt,
        category = other.category,
        access = other.access;

  DeckModel._fromSnapshot(snapshotValue,
      {@required this.uid, @required this.key})
      : assert(uid != null),
        assert(key != null) {
    if (snapshotValue == null) {
      key = null;
      return;
    }
    name = snapshotValue['name'];
    markdown = snapshotValue['markdown'] ?? false;
    type = Enum.fromString(
        snapshotValue['deckType']?.toString()?.toLowerCase(), DeckType.values);
    accepted = snapshotValue['accepted'] ?? false;
    lastSyncAt =
        DateTime.fromMillisecondsSinceEpoch(snapshotValue['lastSyncAt'] ?? 0);
    category = snapshotValue['category'];
    access = Enum.fromString(snapshotValue['access'], AccessType.values);
  }

  @override
  String get rootPath => 'decks/$uid';

  Map<String, dynamic> toMap(bool isNew) {
    final path = '$rootPath/$key';
    // Intentionally flatten the update and exclude "access" field because it is
    // written by DeckAccessModel. Firebase does not allow overlapping updates
    // within a single update() call.
    // Besides, flattening the map allows us to preserve new properties, which
    // tend to appear quite often in DeckModel.
    return {
      '$path/name': name,
      '$path/markdown': markdown,
      '$path/deckType': Enum.asString(type)?.toUpperCase(),
      '$path/accepted': accepted,
      '$path/lastSyncAt': lastSyncAt.toUtc().millisecondsSinceEpoch,
      '$path/category': category,
    };
  }

  static Stream<DeckModel> get({@required String uid, @required String key}) =>
      FirebaseDatabase.instance
          .reference()
          .child('decks')
          .child(uid)
          .child(key)
          .onValue
          .map((evt) =>
              DeckModel._fromSnapshot(evt.snapshot.value, uid: uid, key: key));

  static Stream<DatabaseListEvent<DeckModel>> getList({@required String uid}) {
    FirebaseDatabase.instance
        .reference()
        .child('decks')
        .child(uid)
        .keepSynced(true);

    return fullThenChildEventsStream(
        FirebaseDatabase.instance
            .reference()
            .child('decks')
            .child(uid)
            .orderByKey(), (key, value) {
      _keepDeckSynced(uid, key);
      return DeckModel._fromSnapshot(value, uid: uid, key: key);
    });
  }

  static void _keepDeckSynced(String uid, String deckId) {
    // Install a background listener on Card. The listener is cancelled
    // automatically when the deck is deleted or un-shared, because the security
    // rules will not allow to listen to that node anymore.
    // ScheduledCard is synced within ScheduledCardsBloc.
    FirebaseDatabase.instance
        .reference()
        .child('cards')
        .child(deckId)
        .keepSynced(true);
  }
}
