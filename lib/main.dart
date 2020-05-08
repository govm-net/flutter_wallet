import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/historyPage.dart';
import 'ui/transactionPage.dart';
import 'ui/setting.dart';
import 'ui/home.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/i18n.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);

  runApp(new MyApp());
}

class Choice {
  Choice({this.title, this.icon, this.widget});
  final String title;
  final IconData icon;
  final Widget widget;
}

class BottomNavigationWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new BottomNavigationWidgetState();
  }
}

class BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    
    List<Choice> choices = <Choice>[
      Choice(title: I18n.of(context).home, icon: Icons.home, widget: MyHomePage()),
      Choice(title: I18n.of(context).transaction, icon: Icons.send, widget: TransactionWidget()),
      Choice(title: I18n.of(context).history, icon: Icons.content_paste, widget: HistoryWidget()),
      Choice(title: I18n.of(context).setting, icon: Icons.settings, widget: SettingPageWidget()),
    ];
    
    return new Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          items: choices.map((Choice choice) {
            return new BottomNavigationBarItem(
                icon: Icon(choice.icon), title: Text(choice.title));
          }).toList(),
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (int i) {
            setState(() {
              _currentIndex = i;
            });
          },
        ),
        body: choices[_currentIndex].widget);
  }
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final i18n = I18n.delegate;
    return new MaterialApp(
      title: 'GOVM',
      home: new BottomNavigationWidget(),
      localizationsDelegates: [
        i18n,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate // <-- needed for iOS
      ],
      supportedLocales: i18n.supportedLocales,
    );
  }
}
