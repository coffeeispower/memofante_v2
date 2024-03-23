import 'package:flutter/cupertino.dart';

enum PageSize {
  mobile,
  tablet,
  desktop,
}

/// A State that updates its [size] when the screen size changes.
abstract class ResponsiveState<T extends StatefulWidget> extends State<T> {
  ResponsiveState({mobileThreshold = 600, tabletThreshold = 900}) {
    _mobileThreshold = mobileThreshold;
    _tabletThreshold = tabletThreshold;
  }

  late final int _mobileThreshold;
  late final int _tabletThreshold;
  PageSize size = PageSize.mobile;

  double _width = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSize();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSize();
  }

  void _updateSize() {
    final width = MediaQuery.of(context).size.width;
    if (_width == width) return;
    _width = width;

    if (width < _mobileThreshold) {
      setState(() {
        size = PageSize.mobile;
      });
    } else if (width < _tabletThreshold) {
      setState(() {
        size = PageSize.tablet;
      });
    } else {
      setState(() {
        size = PageSize.desktop;
      });
    }
  }

  Q chooseFromSize<Q>({
    Q? mobile,
    Q? tablet,
    Q? desktop,
  }) {
    switch (size) {
      case PageSize.mobile:
        return mobile ?? tablet ?? desktop!;
      case PageSize.tablet:
        return tablet ?? mobile ?? desktop!;
      case PageSize.desktop:
        return desktop ?? tablet ?? mobile!;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
