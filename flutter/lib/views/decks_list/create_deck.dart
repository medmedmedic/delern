import 'package:flutter/material.dart';

import '../../flutter/localization.dart';
import '../../flutter/styles.dart';
import '../../flutter/user_messages.dart';
import '../../models/card.dart' as card_model;
import '../../models/deck.dart';
import '../../view_models/deck_list_view_model.dart';
import '../card_create_update/card_create_update.dart';
import '../helpers/sign_in_widget.dart';

class CreateDeck extends StatelessWidget {
  const CreateDeck({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          var newDeck = await showDialog<Deck>(
            context: context,
            // User must tap a button to dismiss dialog
            barrierDismissible: false,
            builder: (_) => _CreateDeckDialog(),
          );
          if (newDeck != null) {
            try {
              await DeckListViewModel.createDeck(newDeck);
            } catch (e, stackTrace) {
              UserMessages.showError(() => Scaffold.of(context), e, stackTrace);
              return;
            }
            Navigator.push(
                context,
                MaterialPageRoute(
                    settings: const RouteSettings(name: '/cards/new'),
                    builder: (context) =>
                        CreateUpdateCard(card_model.Card(deck: newDeck))));
          }
        },
      );
}

class _CreateDeckDialog extends StatefulWidget {
  @override
  _CreateDeckDialogState createState() => _CreateDeckDialogState();
}

class _CreateDeckDialogState extends State<_CreateDeckDialog> {
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final addDeckButton = FlatButton(
        child: Text(
          AppLocalizations.of(context).add.toUpperCase(),
          style: TextStyle(
              color: _textController.text.isEmpty
                  ? Theme.of(context).disabledColor
                  : Theme.of(context).accentColor),
        ),
        onPressed: _textController.text.isEmpty
            ? null
            : () {
                Navigator.of(context).pop(Deck(
                    uid: CurrentUserWidget.of(context).user.uid,
                    name: _textController.text));
              });

    final cancelButton = FlatButton(
        onPressed: () {
          Navigator.of(context).pop(null);
        },
        child: Text(
          MaterialLocalizations.of(context).cancelButtonLabel.toUpperCase(),
          style: TextStyle(color: Theme.of(context).accentColor),
        ));

    final deckNameTextField = TextField(
      autofocus: true,
      controller: _textController,
      onChanged: (text) {
        setState(() {});
      },
      style: AppStyles.primaryText,
    );

    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return AlertDialog(
        title: Text(
          AppLocalizations.of(context).deck,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: deckNameTextField,
        ),
        actions: <Widget>[
          cancelButton,
          addDeckButton,
        ],
      );
    } else {
      return HorizontalDialog(
        child: SingleChildScrollView(
          child: Container(
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05),
                child: Row(
                  children: <Widget>[
                    Flexible(child: deckNameTextField),
                    Column(
                      children: <Widget>[
                        addDeckButton,
                        cancelButton,
                      ],
                    )
                  ],
                ),
              )),
        ),
      );
    }
  }
}

class HorizontalDialog extends StatelessWidget {
  const HorizontalDialog({
    Key key,
    this.child,
    this.insetAnimationDuration = const Duration(milliseconds: 100),
    this.insetAnimationCurve = Curves.decelerate,
    this.shape,
  }) : super(key: key);

  final Widget child;

  /// The duration of the animation to show when the system keyboard intrudes
  /// into the space that the dialog is placed in.
  ///
  /// Defaults to 100 milliseconds.
  final Duration insetAnimationDuration;

  /// The curve to use for the animation shown when the system keyboard intrudes
  /// into the space that the dialog is placed in.
  ///
  /// Defaults to [Curves.fastOutSlowIn].
  final Curve insetAnimationCurve;

  /// {@template flutter.material.dialog.shape}
  /// The shape of this dialog's border.
  ///
  /// Defines the dialog's [Material.shape].
  ///
  /// The default shape is a [RoundedRectangleBorder] with a radius of 2.0.
  /// {@endtemplate}
  final ShapeBorder shape;

  Color _getColor(BuildContext context) =>
      Theme.of(context).dialogBackgroundColor;

  static const RoundedRectangleBorder _defaultDialogShape =
      RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2.0)));

  @override
  Widget build(BuildContext context) {
    final dialogTheme = DialogTheme.of(context);
    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets,
      duration: insetAnimationDuration,
      curve: insetAnimationCurve,
      child: Center(
        child: Material(
          elevation: 24.0,
          color: _getColor(context),
          type: MaterialType.card,
          child: child,
          shape: shape ?? dialogTheme.shape ?? _defaultDialogShape,
        ),
      ),
    );
  }
}
