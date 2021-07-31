import 'dart:io';
import 'package:back_pressed/back_pressed.dart';
import 'package:connectivity/connectivity.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:memopie/Check_Connection/No%20Internet.dart';
import 'package:memopie/Push%20Notification/pushNotification.dart';
import 'package:shimmer/shimmer.dart';


class HomePage extends StatefulWidget {
  final String url;

  HomePage({Key? key, required this.url}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FirebaseNotifcation? firebase;
  int checkInt = 0;
  late ConnectivityResult previous;



  handleAsync() async {
    await firebase!.initialize();
    String? token = await firebase!.getToken();
    print("Firebase token : $token");
  }




  @override
  void initState() {
    super.initState();
    firebase = FirebaseNotifcation();
    handleAsync();

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(color: Colors.blue),
      onRefresh: () async {
        if (Platform.isAndroid) {
          _webViewController?.reload();
        } else if (Platform.isIOS) {
          _webViewController?.loadUrl(
              urlRequest: URLRequest(url: await _webViewController?.getUrl()));
        }
      },
    );


    Connectivity().onConnectivityChanged.listen((ConnectivityResult connresult){
      if(connresult == ConnectivityResult.none){
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => No_Internet_Connection()), (route) => false );
      }else if(previous == ConnectivityResult.none){
        // internet conn
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => No_Internet_Connection()), (route) => false );
      }

      previous = connresult;
    });




  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Exit MemoPie',style: TextStyle(fontFamily: "Poppins"),),
        content: new Text('Are you sure wanted to exit this?',),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: new Text(
              'No',
              style: TextStyle(color: Colors.green,fontFamily: "Poppins"),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: new Text(
              'Yes',
              style: TextStyle(color: Colors.red,fontFamily: "Poppins"),
            ),
          ),
        ],
      ),
    )) ??
        false;
  }

  InAppWebViewController? _webViewController;
  double progress = 0;
  String url = '';

  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        javaScriptEnabled: true,
        useShouldOverrideUrlLoading: true,
        useOnDownloadStart: true,
      ),
      android: AndroidInAppWebViewOptions(
        initialScale: 100,
        useShouldInterceptRequest: true,
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  final urlController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnBackPressed(
    perform: (){
        _webViewController!.goBack();


    },
    child: Scaffold(
      // appBar: AppBar(
      //   centerTitle: true,
      //   backgroundColor: Colors.blue,
      //
      //   title: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //     crossAxisAlignment: CrossAxisAlignment.center,
      //     children: [
      //       Image.asset("assets/icon.png",height: 30,width: 30,color: Colors.white,),
      //       Padding(
      //         padding: const EdgeInsets.only(right: 40),
      //         child: Shimmer.fromColors(
      //           baseColor: Colors.white,
      //           highlightColor: Colors.blue,
      //           child: Column(
      //             children: [
      //               Text(
      //                 'MemoPie',
      //                 textAlign: TextAlign.center,
      //                 style: TextStyle(
      //                   fontSize: 22.0,
      //                   fontFamily: "Poppins",
      //                   // fontWeight: FontWeight.bold,
      //                 ),
      //               ),
      //             ],
      //           ),
      //         ),
      //
      //       ),
      //     ],
      //   ),
      //   actions: <Widget>[
      //     IconButton(
      //       onPressed: () {
      //         _webViewController?.goBack();
      //       },
      //       icon: Icon(
      //         Icons.arrow_back_ios,
      //         color: Colors.white,
      //       ),
      //     ),
      //     IconButton(
      //       onPressed: () {
      //         _webViewController?.reload();
      //       },
      //       icon: Icon(
      //         Icons.refresh,
      //         color: Colors.white,
      //       ),
      //     ),
      //     IconButton(
      //       onPressed: () {
      //         _webViewController?.goForward();
      //       },
      //       icon: Icon(
      //         Icons.arrow_forward_ios,
      //         color: Colors.white,
      //       ),
      //     ),
      //
      //     SizedBox(width: 5),
      //   ],
      // ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     _webViewController?.reload();
      //   },
      //   child: Icon(
      //     Icons.refresh, color: Colors.white,
      //
      //   ),
      //   backgroundColor: Colors.blue,
      // ),
      body: SafeArea(
        child: Container(
          child: Column(
            children: [
              progress < 1.0
                  ? LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.blue),
                    )
                  : Center(),
              Expanded(
                child: InAppWebView(
                  key: webViewKey,
                  initialUrlRequest: URLRequest(
                    url: Uri.parse(widget.url),
                    headers: {},
                  ),
                  initialOptions: options,
                  pullToRefreshController: pullToRefreshController,
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url;
                    });
                  },
                  androidOnPermissionRequest:
                      (controller, origin, resources) async {
                    return PermissionRequestResponse(
                        resources: resources,
                        action: PermissionRequestResponseAction.GRANT);
                  },
                  onLoadStop: (controller, url) async {
                    pullToRefreshController.endRefreshing();
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url;
                    });
                  },
                  onLoadError: (controller, url, code, message) {
                    pullToRefreshController.endRefreshing();
                  },
                  onProgressChanged: (controller, progress) {
                    if (progress == 100) {
                      pullToRefreshController.endRefreshing();
                    }
                    setState(() {
                       this.progress = progress / 100;
                      urlController.text = this.url;
                    });
                  },
                  onUpdateVisitedHistory: (controller, url, androidIsReload) {
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url;
                    });
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    print(consoleMessage);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
      );
  }
}
