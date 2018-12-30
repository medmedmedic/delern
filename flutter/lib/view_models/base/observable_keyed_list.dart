import 'dart:async';

import 'package:delern_flutter/models/base/database_list_event.dart';
import 'package:delern_flutter/models/base/keyed_list_item.dart';
import 'package:meta/meta.dart';

@immutable
class ListEvent<T> {
  final ListEventType eventType;
  final Type eventSource;
  final int index;
  final T previousValue;

  const ListEvent({
    @required this.eventType,
    this.index,
    this.eventSource,
    this.previousValue,
  });

  String toString() => '$eventType #$index ($previousValue)';
}

// TODO(dotdoom): hide mutable interface of this list from consumers.
class ObservableKeyedList<T extends KeyedListItem> {
  /// Events generated by calling mutator methods on the source list.
  Stream<ListEvent<T>> get events => _eventsController.stream;
  StreamController<ListEvent<T>> _eventsController;

  List<T> get value => _unmodifiableValue;
  List<T> _unmodifiableValue;
  List<T> _value;

  ObservableKeyedList(this._eventsController);

  int indexOfKey(String key) => _value.indexWhere((item) => item.key == key);

  void _notify(ListEvent<T> event) {
    _unmodifiableValue = List.unmodifiable(_value);
    _eventsController.add(event);
  }

  void move(int takeFromIndex, int insertBeforeIndex, [Type eventSource]) {
    // Adjust because once we move, the index will decrease.
    if (insertBeforeIndex > takeFromIndex) {
      --insertBeforeIndex;
    }
    if (takeFromIndex == insertBeforeIndex) {
      return;
    }
    _value.insert(insertBeforeIndex, _value.removeAt(takeFromIndex));
    _notify(ListEvent(
      eventType: ListEventType.itemMoved,
      eventSource: eventSource,
      index: insertBeforeIndex,
    ));
  }

  void removeAt(int index, [Type eventSource]) => _notify(ListEvent(
      eventType: ListEventType.itemRemoved,
      eventSource: eventSource,
      index: index,
      previousValue: _value.removeAt(index)));

  void insert(int beforeIndex, T value, [Type eventSource]) {
    _value.insert(beforeIndex, value);
    _notify(ListEvent(
        eventType: ListEventType.itemAdded,
        eventSource: eventSource,
        index: beforeIndex));
  }

  void setAt(int index, T value, [Type eventSource]) {
    _value[index] = value;
    _notify(ListEvent(
        eventType: ListEventType.itemChanged,
        eventSource: eventSource,
        index: index));
  }

  void setAll(Iterable<T> newValue, [Type eventSource]) {
    if (_value == null) {
      // Initial data arrival. We were waiting for you!
      _value = newValue.toList();
      _notify(
          ListEvent(eventType: ListEventType.setAll, eventSource: eventSource));
      return;
    }

    // setAll is called when we receive onValue, which can be initial data or an
    // update after listening stream is closed and reopened. For the update, we
    // have to merge, so that the UI shows the old state transitioning to the
    // new state in a slick way.

    for (var index = _value.length - 1; index >= 0; --index) {
      if (!newValue.any((e) => e.key == _value[index].key)) {
        removeAt(index, eventSource);
      }
    }

    var index = 0;
    for (var element in newValue) {
      var existingIndex = indexOfKey(element.key);
      if (existingIndex < 0) {
        insert(index, element, eventSource);
      } else {
        if (existingIndex != index) {
          assert(existingIndex > index,
              'DatabaseListEventProcessor missed an item at re-arrangement');
          move(existingIndex, index, eventSource);
        }
        setAt(index, element, eventSource);
      }
      ++index;
    }
  }
}
