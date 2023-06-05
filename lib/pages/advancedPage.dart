import 'dart:convert';
import 'dart:ui';

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:workout_timer/constants.dart';
import 'package:workout_timer/main.dart';
import 'package:workout_timer/pages/timerpage.dart';
import 'package:workout_timer/providers.dart';
import 'package:workout_timer/services/GenericFunctions.dart';
import 'package:workout_timer/services/NeuButton.dart';
import 'package:workout_timer/services/animIcon/gradientIcon.dart';
import 'package:workout_timer/services/innerShadow.dart';
import 'package:workout_timer/services/myTextField.dart';
import 'package:workout_timer/services/timeValueHandler.dart';

class AdvancedPage extends StatefulWidget {
  @override
  _AdvancedPageState createState() => _AdvancedPageState();
}

class _AdvancedPageState extends State<AdvancedPage>
    with SingleTickerProviderStateMixin {
  double? screenWidth;
  double xOffset = 0;
  double yOffset = 0;
  double scaleFactor = 1;
  double logoAnim = 0;
  bool isBackPressed = false;
  late AnimationController playGradientControl;
  Animation<Color?>? colAnim1, colAnim2;
  TextEditingController dialogController = TextEditingController();
  List<SetClass>? groups = [];
  int totalTimeCount = 0;

  var scrollController;
  ValueNotifier<bool> rebuildVal = ValueNotifier<bool>(false);

  SharedPref prefs = SharedPref();
  List<SavedAdvanced>? savedListObjs;
  List<String>? savedList;
  double scrolloffset = 0;

  // Future<List<SavedAdvanced>> _getAdvData() async {
  //   savedList = await prefs.read('Adv');
  //   savedListObjs = savedList
  //       .map((item) => SavedAdvanced.fromJson(jsonDecode(item)))
  //       .toList();
  //   return savedListObjs;
  // }

  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
    scrollController = ScrollController();
    groups!.add(
      SetClass(
          grpName: 'Group ${groups!.length + 1}',
          timeList: [
            TimeClass(
              name: 'Work',
              isWork: true,
              sec: 30,
            ),
            TimeClass(name: 'Break', isWork: false, sec: 30),
          ],
          sets: 3),
    );

    playGradientControl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
      reverseDuration: Duration(milliseconds: 1000),
    );
    colAnim1 = ColorTween(
      begin: turqoiseGradient[1],
      end: turqoiseGradient[0],
    ).animate(playGradientControl);
    colAnim2 = ColorTween(
      begin: turqoiseGradient[0],
      end: turqoiseGradient[1],
    ).animate(playGradientControl);
    setState(() {
      groups!.first.listenerMaker();
      groups!.first.timeList!.forEach((element) {
        element.initListenerMaker();
      });

      xOffset = 250;
      yOffset = 140;
      isBackPressed = false;
      scaleFactor = 0.7;
      isDrawerOpen = true;
      isAdvancedOpen = false;
    });

    playGradientControl.forward();
    playGradientControl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        playGradientControl.reverse();
      }
      if (status == AnimationStatus.dismissed) {
        playGradientControl.forward();
      }
    });
  }

  void finaliseGroupsList() {
    totalTimeCount = 0;
    groups!.forEach((groupEle) {
      groupEle.sets = int.parse(groupEle.textController.value.text);
      groupEle.grpName = groupEle.nameController.value.text;
      if (groupEle.textController.value.text == '') {
        groupEle.sets = 1;
      }
      if (groupEle.nameController.value.text == '') {
        groupEle.grpName = 'Work';
      }
      int timelistTally = 0;
      groupEle.timeList!.forEach((timeEle) {
        if (timeEle.controllers['name'] == '') {
          timeEle.controllers['name'].value.text = 'Work';
        }
        if (timeEle.controllers['min'] == '') {
          timeEle.controllers['min'] = '0';
        }
        if (timeEle.controllers['sec'] == '') {
          timeEle.controllers['sec'] = '30';
        }
        timeEle.name = timeEle.controllers['name'].value.text;
        timeEle.sec = Duration(
          minutes: int.parse(timeEle.controllers['min'].value.text),
          seconds: int.parse(timeEle.controllers['sec'].value.text),
        ).inSeconds;
        timelistTally += timeEle.sec!;
      });
      totalTimeCount += timelistTally * groupEle.sets!;
    });
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    dialogController.dispose();
    groups!.forEach((element) {
      element.nameController.dispose();
      element.textController.dispose();
      element.timeList!.forEach((ele) {
        ele.controllers.forEach((key, value) {
          ele.controllers[key].dispose();
        });
      });
    });
    super.dispose();
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (isAdvancedOpen) {
      setState(() {
        isBackPressed = true;
        xOffset = adjusted(250);
        yOffset = adjusted(140);
        scaleFactor = 0.7;
        isDrawerOpen = true;
        isAdvancedOpen = false;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isAdvancedOpen ? Brightness.dark : Brightness.light,
          systemNavigationBarColor:
              isAdvancedOpen ? backgroundC[0] : drawerColor,
          systemNavigationBarIconBrightness:
              isAdvancedOpen ? Brightness.dark : Brightness.light,
          systemNavigationBarDividerColor:
              isAdvancedOpen ? backgroundC[0] : drawerColor,
        ));
      });
      return true;
    } else
      return false;
  }

  double adjusted(double val) => val * screenWidth! * perPixel;

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;

    return Consumer(
      builder: (context, ref, child) {
        bool isDark = ref.read(isDarkProvider);
        Color backgroundColor = ref.watch(backgroundProvider);
        Color shadowColor = ref.watch(shadowProvider);
        Color lightShadowColor = ref.watch(lightShadowProvider);
        Color textColor = ref.watch(textProvider);
        return ValueListenableBuilder(
          valueListenable: indexOfMenu,
          builder: (context, dynamic val, child) {
            if (!isAdvancedOpen && indexOfMenu.value == 5 && !isBackPressed) {
              if (editGroups!.isNotEmpty) groups = editGroups;
              Future.delayed(Duration(microseconds: 1)).then((value) {
                setState(() {
                  xOffset = 0;
                  yOffset = 0;
                  scaleFactor = 1;
                  isDrawerOpen = false;
                  isAdvancedOpen = true;
                });
              });
            } else if (indexOfMenu.value != 5) isBackPressed = false;
            return child!;
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: drawerAnimDur),
            curve: Curves.easeInOutQuart,
            transform: Matrix4.translationValues(xOffset, yOffset, 100)
              ..scale(scaleFactor),
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            onEnd: (() {
              if (isAdvancedOpen && indexOfMenu.value == 5) {
                SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness:
                      isAdvancedOpen ? Brightness.dark : Brightness.light,
                  systemNavigationBarColor:
                      isAdvancedOpen ? backgroundColor : drawerColor,
                  systemNavigationBarIconBrightness:
                      isAdvancedOpen ? Brightness.dark : Brightness.light,
                  systemNavigationBarDividerColor:
                      isAdvancedOpen ? backgroundColor : drawerColor,
                ));
              }
            }),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(isDrawerOpen ? 28 : 0),
            ),
            child: GestureDetector(
              onTap: (() {
                if (!isAdvancedOpen && indexOfMenu.value == 5) {
                  setState(() {
                    xOffset = 0;
                    yOffset = 0;
                    scaleFactor = 1;
                    isDrawerOpen = false;
                    isAdvancedOpen = true;
                  });
                }
              }),
              onHorizontalDragEnd: ((_) {
                if (!isAdvancedOpen && indexOfMenu.value == 5) {
                  setState(() {
                    xOffset = 0;
                    yOffset = 0;
                    scaleFactor = 1;
                    isDrawerOpen = false;
                    isAdvancedOpen = true;
                  });
                }
              }),
              child: AbsorbPointer(
                absorbing: !isAdvancedOpen,
                child: Container(
                  height: double.infinity,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius:
                        BorderRadius.circular(isAdvancedOpen ? 0 : 28),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 50,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.only(left: 27),
                                child: Text(
                                  'Advanced',
                                  style: TextStyle(
                                    color: textColor,
                                    letterSpacing: 2.0,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              NeuButton(
                                ico: Icon(
                                  Icons.menu_rounded,
                                  size: 30,
                                  color: textColor,
                                ),
                                onPress: (() {
                                  setState(() {
                                    isBackPressed = true;
                                    xOffset = adjusted(250);
                                    yOffset = adjusted(140);
                                    scaleFactor = 0.7;
                                    isDrawerOpen = true;
                                    isAdvancedOpen = false;
                                    SystemChrome.setSystemUIOverlayStyle(
                                        SystemUiOverlayStyle(
                                      statusBarColor: Colors.transparent,
                                      statusBarIconBrightness: isAdvancedOpen
                                          ? Brightness.dark
                                          : Brightness.light,
                                      systemNavigationBarColor: isAdvancedOpen
                                          ? backgroundColor
                                          : drawerColor,
                                      systemNavigationBarIconBrightness:
                                          isAdvancedOpen
                                              ? Brightness.dark
                                              : Brightness.light,
                                      systemNavigationBarDividerColor:
                                          isAdvancedOpen
                                              ? backgroundColor
                                              : drawerColor,
                                    ));
                                  });
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 30,
                        child: NotificationListener(
                          // oniNotfication: (t) {
                          //   if (t is ScrollEndNotification) {
                          //     scrolloffset =scrollController.position.pixels;
                          //   }
                          //   return false;
                          // },
                          child: AnimatedList(
                            controller: scrollController,
                            initialItemCount: groups!.length,
                            key: ValueKey('0${groups!.length}'),
                            physics: BouncingScrollPhysics(),
                            itemBuilder:
                                (BuildContext context, int index, animation) {
                              return Dismissible(
                                background: Container(
                                  padding: EdgeInsets.only(left: 30),
                                  alignment: Alignment.centerLeft,
                                  child:
                                      Wrap(direction: Axis.vertical, children: [
                                    RotatedBox(
                                        quarterTurns: 3,
                                        child: Center(
                                          child: Text(
                                            'Delete',
                                            style: kTextStyle.copyWith(
                                              color: textColor,
                                              fontSize: 28,
                                            ),
                                          ),
                                        )),
                                  ]),
                                  // child: Icon(Icons.delete_outline_rounded,size: 40,color: textColor,)
                                ),
                                direction: groups!.length == 1
                                    ? DismissDirection.none
                                    : DismissDirection.horizontal,
                                key: ValueKey('$index name'),
                                onDismissed: (direction) async {
                                  setState(() {
                                    groups!.removeAt(index);
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  margin: EdgeInsets.symmetric(
                                      vertical: 15, horizontal: 20),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 15, horizontal: 15),
                                  height: groups![index].height,
                                  width: screenWidth,
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    // gradient: LinearGradient(
                                    //     colors: gradientList[index % 5],
                                    //     begin: Alignment.centerLeft,
                                    //     end: Alignment.centerRight),
                                    borderRadius: BorderRadius.circular(32),
                                    boxShadow: [
                                      BoxShadow(
                                          color: shadowColor,
                                          offset: Offset(8, 6),
                                          blurRadius: 12),
                                      BoxShadow(
                                          color: lightShadowColor,
                                          offset: Offset(-8, -6),
                                          blurRadius: 12),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            flex: 15,
                                            child: TextField(
                                              keyboardType: TextInputType.name,
                                              controller:
                                                  groups![index].nameController,
                                              style: kTextStyle.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 25,
                                                color: textColor,
                                              ),
                                              textAlign: TextAlign.center,
                                              decoration: kInputDecor,
                                              cursorColor: Colors.grey,
                                            ),
                                            // Text(
                                            //   groups[index].grpName,
                                            //   style: kTextStyle.copyWith(
                                            //     color:textColor,
                                            //     // backgroundColor,
                                            //     fontWeight: FontWeight.bold,
                                            //     fontSize: 26.5,
                                            //   ),
                                            // ),
                                          ),
                                          Expanded(
                                            flex: 4,
                                            child: NeuButton(
                                              length: 50,
                                              breadth: 50,
                                              ico: FaIcon(
                                                FontAwesomeIcons.plus,
                                                color: textColor,
                                                size: 20,
                                              ),
                                              onPress: (() {
                                                SetClass temp = groups![index];
                                                temp.timeList!
                                                    .add(new TimeClass(
                                                  name: 'Work',
                                                  isWork: true,
                                                  sec: 30,
                                                ));
                                                setState(() {
                                                  groups![index] = temp;
                                                  groups![index].height += 68;
                                                });

                                                rebuildVal.value =
                                                    rebuildVal.value
                                                        ? false
                                                        : true;
                                              }),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Expanded(
                                        child: AnimatedList(
                                            initialItemCount:
                                                groups![index].timeList!.length,
                                            shrinkWrap: true,
                                            physics: BouncingScrollPhysics(),
                                            key: ValueKey(
                                                '${groups![index].timeList!.length}'),
                                            itemBuilder: (BuildContext context,
                                                int j, animation) {
                                              return Dismissible(
                                                background: Container(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    'Delete',
                                                    style: kTextStyle.copyWith(
                                                      color: textColor,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                  // child: Icon(Icons.delete_outline_rounded,size: 40,color: textColor,)
                                                ),
                                                direction:
                                                    DismissDirection.horizontal,
                                                key: ValueKey('1010'),
                                                onDismissed: (direction) {
                                                  groups![index]
                                                      .timeList![j]
                                                      .controllers
                                                      .forEach((key, value) {
                                                    groups![index]
                                                        .timeList![j]
                                                        .controllers[key]
                                                        .dispose();
                                                  });
                                                  groups![index]
                                                      .timeList!
                                                      .removeAt(j);
                                                  Future.delayed(Duration(
                                                          microseconds: 1))
                                                      .then((value) =>
                                                          setState(() {
                                                            groups![index]
                                                                .height -= 68;
                                                          }));
                                                },
                                                child: Container(
                                                  decoration: ConcaveDecoration(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        lerpDouble(
                                                            0, 100, 0.25)!,
                                                      ),
                                                    ),
                                                    colors: [
                                                      shadowColor,
                                                      lightShadowColor
                                                    ],
                                                    depression: 10,
                                                  ),
                                                  width: screenWidth! - 40,
                                                  margin: EdgeInsets.symmetric(
                                                      vertical: 5,
                                                      horizontal: 0),
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 0,
                                                      horizontal: 5),
                                                  child: Container(
                                                    child: Theme(
                                                      data: Theme.of(context)
                                                          .copyWith(
                                                              dividerColor: Colors
                                                                  .transparent),
                                                      child: ExpansionTile(
                                                        childrenPadding:
                                                            EdgeInsets.only(
                                                                bottom: 10),
                                                        maintainState: true,
                                                        key: ValueKey(
                                                            '$index + $j +name'),
                                                        onExpansionChanged:
                                                            (val) {
                                                          setState(() {
                                                            val
                                                                ? groups![index]
                                                                        .height +=
                                                                    68
                                                                : groups![index]
                                                                    .height -= 68;
                                                          });
                                                        },
                                                        title: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Expanded(
                                                              flex: 5,
                                                              child: TextField(
                                                                keyboardType:
                                                                    TextInputType
                                                                        .name,
                                                                controller: groups![
                                                                        index]
                                                                    .timeList![
                                                                        j]
                                                                    .controllers['name'],
                                                                style: kTextStyle
                                                                    .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 20,
                                                                  color: isDark
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                decoration:
                                                                    kInputDecor,
                                                                cursorColor:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: TextField(
                                                                keyboardType:
                                                                    TextInputType
                                                                        .number,
                                                                controller: groups![
                                                                        index]
                                                                    .timeList![
                                                                        j]
                                                                    .controllers['min'],
                                                                style: kTextStyle
                                                                    .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 20,
                                                                  color: isDark
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                decoration:
                                                                    kInputDecor,
                                                                cursorColor:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                            Text(
                                                              ':',
                                                              style: kTextStyle
                                                                  .copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 20,
                                                                color:
                                                                    textColor,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              flex: 2,
                                                              child: TextField(
                                                                keyboardType:
                                                                    TextInputType
                                                                        .number,
                                                                controller: groups![
                                                                        index]
                                                                    .timeList![
                                                                        j]
                                                                    .controllers['sec'],
                                                                style: kTextStyle
                                                                    .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 20,
                                                                  color: isDark
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                decoration:
                                                                    kInputDecor,
                                                                cursorColor:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                flex: 1,
                                                                child:
                                                                    SizedBox(),
                                                              ),
                                                              Expanded(
                                                                flex: 4,
                                                                child:
                                                                    FittedBox(
                                                                  fit: BoxFit
                                                                      .fill,
                                                                  child: Text(
                                                                    'Type:',
                                                                  ),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 1,
                                                                child:
                                                                    SizedBox(),
                                                              ),
                                                              Expanded(
                                                                flex: 10,
                                                                child:
                                                                    GestureDetector(
                                                                  onTap:
                                                                      (() async {
                                                                    setState(
                                                                        () {
                                                                      groups![index]
                                                                          .timeList![
                                                                              j]
                                                                          .isWork = true;
                                                                    });
                                                                  }),
                                                                  child:
                                                                      AnimatedContainer(
                                                                    duration: Duration(
                                                                        milliseconds:
                                                                            200),
                                                                    curve: Curves
                                                                        .easeOutQuint,
                                                                    height: 45,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: groups![index]
                                                                              .timeList![
                                                                                  j]
                                                                              .isWork!
                                                                          ? textColor.withOpacity(
                                                                              0.5)
                                                                          : Colors
                                                                              .transparent,
                                                                      border: Border.all(
                                                                          width:
                                                                              1,
                                                                          color: Colors
                                                                              .white
                                                                              .withOpacity(0.8)),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              20),
                                                                    ),
                                                                    child:
                                                                        Center(
                                                                      child:
                                                                          Text(
                                                                        'Work',
                                                                        style:
                                                                            TextStyle(
                                                                          color: groups![index].timeList![j].isWork!
                                                                              ? backgroundColor
                                                                              : textColor,
                                                                          letterSpacing:
                                                                              2.0,
                                                                          fontSize:
                                                                              20,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 1,
                                                                child:
                                                                    SizedBox(),
                                                              ),
                                                              Expanded(
                                                                flex: 10,
                                                                child:
                                                                    GestureDetector(
                                                                  onTap:
                                                                      (() async {
                                                                    setState(
                                                                        () {
                                                                      groups![index]
                                                                          .timeList![
                                                                              j]
                                                                          .isWork = false;
                                                                    });
                                                                  }),
                                                                  child:
                                                                      AnimatedContainer(
                                                                    duration: Duration(
                                                                        milliseconds:
                                                                            200),
                                                                    curve: Curves
                                                                        .easeOutQuint,
                                                                    height: 45,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: !groups![index]
                                                                              .timeList![
                                                                                  j]
                                                                              .isWork!
                                                                          ? textColor.withOpacity(
                                                                              0.5)
                                                                          : Colors
                                                                              .transparent,
                                                                      border: Border.all(
                                                                          width:
                                                                              1,
                                                                          color: Colors
                                                                              .white
                                                                              .withOpacity(0.8)),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              20),
                                                                    ),
                                                                    child:
                                                                        Center(
                                                                      child:
                                                                          Text(
                                                                        'Rest',
                                                                        style:
                                                                            TextStyle(
                                                                          color: !groups![index].timeList![j].isWork!
                                                                              ? backgroundColor
                                                                              : textColor,
                                                                          letterSpacing:
                                                                              2.0,
                                                                          fontSize:
                                                                              20,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 1,
                                                                child:
                                                                    SizedBox(),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                      ),
                                      Row(

                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          // SizedBox(
                                          //   width: 10,
                                          // ),
                                          Text(
                                            'Sets :',
                                            style: kTextStyle.copyWith(
                                              color: textColor,
                                              // backgroundColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20.5,
                                            ),
                                          ),
                                          NeuButton(
                                            length: 50,
                                            breadth: 50,
                                            ico: Icon(
                                              Icons.remove_rounded,
                                              size: 20,
                                              color: textColor,
                                            ),
                                            onPress: (() {
                                              groups![index].addRemove(false);
                                            }),
                                          ),
                                          Container(
                                            width: 40,
                                            child: myTextField(
                                              keyboardType:
                                                  TextInputType.number,
                                              isStringName: false,
                                              control:
                                                  groups![index].textController,
                                              func: (val) {
                                                setState(() {
                                                  groups![index].retain = val;
                                                  groups![index]
                                                      .textController
                                                      .text = val;
                                                });
                                              },
                                            ),
                                          ),
                                          NeuButton(
                                            length: 50,
                                            breadth: 50,
                                            ico: Icon(
                                              Icons.add_rounded,
                                              size: 20,
                                              color: textColor,
                                            ),
                                            onPress: (() {
                                              groups![index].addRemove(true);
                                            }),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              NeuButton(
                                ico: Icon(
                                  Icons.save_outlined,
                                  size: 30,
                                  color: textColor,
                                ),
                                onPress: (() async {
                                  await createDialog(
                                      context,
                                      isDark,
                                      backgroundColor,
                                      textColor,
                                      shadowColor,
                                      lightShadowColor);
                                  finaliseGroupsList();
                                  savedList = await prefs.read('Adv');
                                  SavedAdvanced _data = SavedAdvanced(
                                    name:
                                        stringFormatter(dialogController.text),
                                    groups: groups,
                                    totalTime: totalTimeCount,
                                  );
                                  print(
                                      'Encoded ${jsonEncode(_data.toJson())}');
                                  savedList!.add(jsonEncode(_data.toJson()));
                                  await prefs.save('Adv', savedList!);
                                }),
                              ),
                              AnimatedBuilder(
                                animation: playGradientControl,
                                builder: (BuildContext context, Widget? child) {
                                  return NeuButton(
                                    ico: GradientIcon(
                                      icon: Icons.play_arrow_rounded,
                                      size: 55,
                                      gradient: RadialGradient(colors: <Color>[
                                        colAnim1!.value!,
                                        colAnim2!.value!,
                                      ], focal: Alignment.centerLeft),
                                    ),
                                    length: screenWidth! / 4.6,
                                    breadth: screenWidth! / 4.6,
                                    radii: 50,
                                    onPress: (() async {
                                      FocusScopeNode currentFocus =
                                          FocusScope.of(context);
                                      if (!currentFocus.hasPrimaryFocus) {
                                        currentFocus.unfocus();
                                      }
                                      finaliseGroupsList();
                                      final page = TimerPage(
                                        isRest: false,
                                        args: groups,
                                        breakTime: TimeClass(sec: 0),
                                        totalTime: totalTimeCount,
                                      );
                                      // await Future.delayed(Duration(microseconds: 1));
                                      await Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                              transitionDuration:
                                                  Duration(milliseconds: 250),
                                              reverseTransitionDuration:
                                                  Duration(milliseconds: 150),
                                              transitionsBuilder: (BuildContext
                                                      context,
                                                  Animation<double> animation,
                                                  Animation<double>
                                                      secAnimation,
                                                  Widget child) {
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: child,
                                                );
                                              },
                                              pageBuilder: (BuildContext
                                                      context,
                                                  Animation<double> animation,
                                                  Animation<double>
                                                      secAnimation) {
                                                return page;
                                              }));
                                    }),
                                  );
                                },
                              ),
                              NeuButton(
                                ico: FaIcon(
                                  FontAwesomeIcons.plus,
                                  color: textColor,
                                  size: 25,
                                ),
                                onPress: (() {
                                  setState(() {
                                    groups!.add(
                                      SetClass(
                                          grpName:
                                              'Group ${groups!.length + 1}',
                                          timeList: [
                                            TimeClass(
                                              name: 'Work',
                                              isWork: true,
                                              sec: 30,
                                            ),
                                            TimeClass(
                                                name: 'Break',
                                                isWork: false,
                                                sec: 30),
                                          ],
                                          sets: 3),
                                    );
                                    Future.delayed(Duration(microseconds: 1))
                                        .then((value) {
                                      scrollController.animateTo(
                                        scrollController
                                            .position.maxScrollExtent,
                                        curve: Curves.easeOut,
                                        duration:
                                            const Duration(milliseconds: 100),
                                      );
                                    });
                                  });
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String?> createDialog(
      BuildContext context,
      bool isDark,
      Color backgroundColor,
      Color textColor,
      Color shadowColor,
      Color lightShadowColor) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          backgroundColor: backgroundColor,
          titlePadding: EdgeInsets.fromLTRB(30, 30, 30, 10),
          contentPadding: EdgeInsets.fromLTRB(30, 10, 30, 10),
          actionsPadding: EdgeInsets.only(
              top: 10,
              bottom: 15,
              right: MediaQuery.of(context).size.width / 4),
          title: Center(
            child: Text(
              'Enter Workout Name',
              style: TextStyle(
                color: textColor,
                fontSize: 22,
              ),
            ),
          ),
          content: AnimatedBuilder(
              animation: playGradientControl,
              builder: (BuildContext context, Widget? child) {
                return Container(
                  height: 150,
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colAnim1!.value!,
                        colAnim2!.value!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: shadowColor,
                          offset: Offset(8, 6),
                          blurRadius: 12),
                      BoxShadow(
                          color: lightShadowColor,
                          offset: Offset(-8, -6),
                          blurRadius: 12),
                    ],
                  ),
                  child: TextField(
                    keyboardType: TextInputType.name,
                    controller: dialogController,
                    style: kTextStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    decoration: kInputDecor,
                    cursorColor: Colors.grey,
                  ),
                );
              }),
          actions: [
            Center(
              child: MaterialButton(
                onPressed: (() {
                  if (dialogController.value.text != '') {
                    Navigator.pop(context);
                  }
                }),
                child: Text(
                  'Save',
                  style: kTextStyle.copyWith(
                    fontSize: 25,
                    color: isDark ? Colors.white : Colors.black,
                    fontFamily: 'MontserratBold',
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }
}
