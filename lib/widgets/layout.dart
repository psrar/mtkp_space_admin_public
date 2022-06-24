// ignore_for_file: file_names

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

class GroupSelector extends StatelessWidget {
  final String selectedGroup;
  final List<String> options;
  final Function(String)? callback;
  const GroupSelector(
      {Key? key,
      required this.selectedGroup,
      required this.options,
      required this.callback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColorLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
            onTap: () => showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: const Text('Выберите группу'),
                    insetPadding: const EdgeInsets.all(60),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height - 200,
                        width: 300,
                        child: ListView.separated(
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(
                                  options[index],
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  callback?.call(options[index]);
                                },
                              );
                            },
                            separatorBuilder: (context, index) => const Divider(
                                  color: Colors.grey,
                                  thickness: 1,
                                  height: 0,
                                ),
                            itemCount: options.length),
                      ),
                    ],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  );
                }),
            borderRadius: BorderRadius.circular(6),
            child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(selectedGroup),
                ))));
  }
}

class SlideTransitionDraft extends StatelessWidget {
  final Widget child;
  const SlideTransitionDraft({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (
          Widget child,
          Animation<double> primaryAnimation,
          Animation<double> secondaryAnimation,
        ) {
          var c = CurveTween(curve: Curves.easeOutCubic);
          primaryAnimation = primaryAnimation.drive(c);
          secondaryAnimation = secondaryAnimation.drive(c);
          return FadeTransition(
            opacity: ReverseAnimation(secondaryAnimation),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(0.0, -0.2),
              ).animate(secondaryAnimation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset.zero,
                  end: const Offset(0.0, 0.4),
                ).animate(ReverseAnimation(primaryAnimation)),
                child: FadeTransition(
                  opacity: primaryAnimation,
                  child: child,
                ),
              ),
            ),
          );
        },
        child: child);
  }
}

class ColoredTextButton extends StatelessWidget {
  final Function onPressed;
  final Color foregroundColor;
  final Color boxColor;
  final Color splashColor;
  final String text;
  final bool outlined;
  const ColoredTextButton(
      {Key? key,
      required this.onPressed,
      required this.text,
      this.foregroundColor = Colors.white,
      required this.boxColor,
      this.splashColor = Colors.white,
      this.outlined = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () => onPressed.call(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(text,
              style: TextStyle(color: foregroundColor, fontSize: 16)),
        ),
        style: outlined == true
            ? TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: boxColor),
                    borderRadius: BorderRadius.circular(8)),
                primary: splashColor)
            : TextButton.styleFrom(
                backgroundColor: boxColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                primary: splashColor));
  }
}

InputDecoration standardInputDecoration(String text, IconData icon) =>
    InputDecoration(
      hintText: text,
      hintStyle: TextStyle(color: Colors.grey.shade700, fontSize: 20),
      prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
      contentPadding: const EdgeInsets.all(6),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black12)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue)),
    );

showTextSnackBar(BuildContext context, String text, int milliseconds) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(text),
    behavior: SnackBarBehavior.floating,
    duration: Duration(milliseconds: milliseconds),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ));
}
