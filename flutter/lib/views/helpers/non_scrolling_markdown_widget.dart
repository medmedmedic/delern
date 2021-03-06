import 'package:delern_flutter/views/helpers/display_image_widget.dart';
import 'package:delern_flutter/views/helpers/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class NonScrollingMarkdownWidget extends StatelessWidget {
  final String text;
  final TextStyle textStyle;

  const NonScrollingMarkdownWidget({this.text, this.textStyle});

  @override
  Widget build(BuildContext context) => Center(
        child: MarkdownBody(
          data: text,
          // Unfortunately, selectable currently breaks column sizing in tables.
          //selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: textStyle,
            listBullet: textStyle,
            textScaleFactor: MediaQuery.of(context).textScaleFactor,
            // The default is symmetric(horizontal: 16, vertical: 8).
            tableCellsPadding: const EdgeInsets.all(6),
            tableColumnWidth: const IntrinsicColumnWidth(),
          ),
          // Use custom image builder to have loading
          imageBuilder: (uri) => buildDisplayImageWidget(uri.toString()),
          onTapLink: (href) => launchUrl(href, context),
        ),
      );
}
