import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final double elevation;
  final bool showBackButton;

  const CustomAppBar({
    Key? key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.bottom,
    this.centerTitle = true,
    this.elevation = 2,
    this.showBackButton = true,
  })  : assert(title != null || titleWidget != null,
            'Either title or titleWidget must be provided'),
        super(key: key);

  @override
  Size get preferredSize {
    final height = kToolbarHeight + (bottom?.preferredSize.height ?? 0);
    return Size.fromHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    final titleContent = titleWidget ??
        Text(
          title ?? '',
          style: const TextStyle(color: Colors.white),
        );

    return Material(
      elevation: elevation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: kToolbarHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(child: titleContent),
                    if (leading != null)
                      Positioned(
                        left: 0,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: leading!,
                        ),
                      )
                    else if (showBackButton)
                      Positioned(
                        left: 0,
                        child: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: Navigator.canPop(context)
                              ? () => Navigator.of(context).maybePop()
                              : null,
                        ),
                      ),
                    if (actions != null)
                      Positioned(
                        right: 0,
                        child: Row(children: actions!),
                      ),
                  ],
                ),
              ),
              if (bottom != null) bottom!,
            ],
          ),
        ),
      ),
    );
  }
}
