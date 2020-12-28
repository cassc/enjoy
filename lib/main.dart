import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path_provider/path_provider.dart';

import 'common.dart';

const DEBUG = true;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Enjoy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Enjoy'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = const MethodChannel('enjoy/uidquery');
  Map<String, int> _uidByPkg = {};

  List<Application> _apps = [];

  bool _loading = false;

  void _getAppList() async {
    setState(() {
      _loading = true;
    });
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeSystemApps: true,
      includeAppIcons: true,
    );

    if (apps == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    if (DEBUG) {
      for (var item in apps) {
        if (item.systemApp) {
          log("found system App: $item");
        }
      }
    }

    apps.sort((a1, a2) {
      return a1.packageName.compareTo(a2.packageName);
    });

    await _loadAllUids(apps);

    setState(() {
      _apps = apps;
      _loading = false;
    });
  }

  _getUidByPackage(String pkg) async {
    try {
      int uid = await platform.invokeMethod('queryUid', pkg);
      if (DEBUG) {
        log('pkg: $pkg uid: $uid');
      }
      return uid;
    } on PlatformException catch (e) {
      log('queryUid error: $e');
      return 'ERR';
    }
  }

  _openApp(Application app) async {
    DeviceApps.openApp(app.packageName);
  }

  _loadAllUids(List<Application> apps) async {
    for (var app in apps) {
      var uid = await _getUidByPackage(app.packageName);
      _uidByPkg.update(app.packageName, (value) => uid, ifAbsent: () => uid);
    }
  }

  _appToCsv(List<Application> apps) {
    var data = 'name,pkg,issys,uid\r\n';
    for (var app in apps) {
      var name = app.appName;
      var pkg = app.packageName;
      bool isSys = app.systemApp;
      var uid = _uidByPkg[pkg];
      data = '$data$name,$pkg,$isSys,$uid\r\n';
    }
    return data;
  }

  _formatAppAsStr(Application app){
    var pkg = app.packageName;
    // var apk = app.apkFilePath;
    var data = app.dataDir;
    var isSys = app.systemApp;
    var install = DateTime.fromMillisecondsSinceEpoch(app.installTimeMillis);
    var update = DateTime.fromMillisecondsSinceEpoch(app.updateTimeMillis);
    
    return '''
Package:\n$pkg\n
Data path:\n$data\n
System App?\n$isSys\n
Installed on:\n$install\n
Updated on:\n$update\n
    ''';
  }

  _export() async {
    try {
      setState(() {
        _loading = true;
      });
      final directory = await getApplicationDocumentsDirectory();
      final root = directory.path;

      var path = '$root/allapps.csv';
      var file = File(path);
      String csv = await _appToCsv(_apps);
      await file.writeAsString(csv);

      final params = SaveFileDialogParams(sourceFilePath: path);
      final filePath = await FlutterFileDialog.saveFile(params: params);

      if (filePath != null) {
        log('File saved to $filePath');
        String title = 'Success';
        String body = 'Export success!';
        popup(context, title, body);
      } else {
        log('Backup canceled');
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildAppItem(Application application) {
    var app = application as ApplicationWithIcon;
    var title = app.appName;
    var pkg = app.packageName;
    var isSys = app.systemApp;
    var color = isSys ? Colors.red : Colors.black;
    var uid = _uidByPkg[pkg] ?? 'Click to load UID';
    final img = Image.memory(app.icon);
    return Card(
      elevation: 12,
      margin: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          ListTile(
            leading: GestureDetector(
              child: img,
              onTap: () async {
                await _openApp(app);
              },
            ),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$title',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                SizedBox(
                  height: 8,
                ),
                Text(
                  '$pkg',
                  style: TextStyle(color: color, fontSize: 9.0),
                ),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
            subtitle: Text(
              '$uid',
              style: TextStyle(color: color),
            ),
            onTap: (){
              popup(context, '$title', _formatAppAsStr(app));
            },
          ),
        ],
      ),
    );
  }

  Widget _appListWidget() {
    if (_apps.length < 1) {
      return Center(
        child: Text("Please click the circle button to load apps."),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(8.0),
      itemCount: _apps.length,
      itemBuilder: (context, index) {
        return _buildAppItem(_apps[index]);
      },
    );
  }

  final _spinner = Center(
    child: Container(
      height: 120.0,
      child: Column(
        children: [
          SpinKitRotatingCircle(
            color: Colors.green,
            size: 80.0,
          ),
          Text(
            'Please wait ...',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    var n = _apps.length;
    var titleCol = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [Text('$n Apps Found')],
    );

    var actions = [
      IconButton(
        icon: Icon(Icons.panorama_fish_eye),
        onPressed: _getAppList,
      ),
      IconButton(
        onPressed: _export,
        icon: Icon(Icons.file_download),
      )
    ];

    if (_loading) {
      actions = [];
    }

    return Scaffold(
      appBar: AppBar(
        title: titleCol,
        actions: actions,
      ),
      body: _loading ? _spinner : _appListWidget(),
    );
  }
}
