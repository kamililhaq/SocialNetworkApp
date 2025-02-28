
import 'dart:io';
import 'package:kamililhaq/models/user.dart';
import 'package:kamililhaq/pages/CreateAccountPage.dart';
import 'package:kamililhaq/pages/NotificationsPage.dart';
import 'package:kamililhaq/pages/ProfilePage.dart';
import 'package:kamililhaq/pages/SearchPage.dart';
import 'package:kamililhaq/pages/TimeLinePage.dart';
import 'package:kamililhaq/pages/UploadPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';


final GoogleSignIn gSignIn = GoogleSignIn();
final usersReference = Firestore.instance.collection("users");
final StorageReference storageReference = FirebaseStorage.instance.ref().child("Posts Pictures");
final postsReference = Firestore.instance.collection("posts");
final activityFeedReference = Firestore.instance.collection("feed");
final commentsRefrence = Firestore.instance.collection("comments");
final followersRefrence = Firestore.instance.collection("followers");
final followingRefrence = Firestore.instance.collection("following");
final timelineRefrence = Firestore.instance.collection("timeline");

final DateTime timestamp = DateTime.now();
User currentUser;


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}


class _HomePageState extends State<HomePage>
{
  bool isSignedIn = false;
  PageController pageController;
  int getPageIndex = 0;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final _scaffoldKey = GlobalKey<ScaffoldState>();


  void initState(){
    super.initState();

    pageController = PageController();

    gSignIn.onCurrentUserChanged.listen((gSigninAccount){
      controlSignIn(gSigninAccount);
    }, onError: (gError){
      print("Error Message: " + gError);
    });

    gSignIn.signInSilently(suppressErrors: false).then((gSignInAccount){
      controlSignIn(gSignInAccount);
    }).catchError((gError){
      print("Error Message: " + gError);
    });
  }

  controlSignIn(GoogleSignInAccount signInAccount) async
  {
    if(signInAccount != null)
    {
      await saveUserInfoToFireStore();

      setState(() {
        isSignedIn = true;
      });

      configureRealTimePushNotifications();
    }
    else
    {
      setState(() {
        isSignedIn = false;
      });
    }
  }

  configureRealTimePushNotifications()
  {
    final GoogleSignInAccount gUser = gSignIn.currentUser;

    if(Platform.isIOS)
    {
      getIOSPermissions();
    }

    _firebaseMessaging.getToken().then((token){
      usersReference.document(gUser.id).updateData({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> msg) async
      {
        final String recipientId = msg["data"]["recipient"];
        final String body = msg["notification"]["body"];

        if(recipientId == gUser.id)
        {
          SnackBar snackBar = SnackBar(
            backgroundColor: Colors.grey,
            content: Text(body, style: TextStyle(color: Colors.black), overflow: TextOverflow.ellipsis,),
          );
          _scaffoldKey.currentState.showSnackBar(snackBar);
        }
      },
    );
  }

  getIOSPermissions()
  {
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(alert: true, badge: true, sound: true));

    _firebaseMessaging.onIosSettingsRegistered.listen((settings){
      print("Settings Registered :  $settings");
    });
  }

  saveUserInfoToFireStore() async {
    final GoogleSignInAccount gCurrentUser = gSignIn.currentUser;
    DocumentSnapshot documentSnapshot = await usersReference.document(gCurrentUser.id).get();

    if(!documentSnapshot.exists){
      final username = await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateAccountPage()));

      usersReference.document(gCurrentUser.id).setData({
        "id": gCurrentUser.id,
        "profileName": gCurrentUser.displayName,
        "username": username,
        "url": gCurrentUser.photoUrl,
        "email": gCurrentUser.email,
        "bio": "",
        "timestamp": timestamp,
      });

      await followersRefrence.document(gCurrentUser.id).collection("userFollowers").document(gCurrentUser.id).setData({});

      documentSnapshot = await usersReference.document(gCurrentUser.id).get();
    }

    currentUser = User.fromDocument(documentSnapshot);
  }

  void dispose(){
    pageController.dispose();
    super.dispose();
  }

  loginUser(){
    gSignIn.signIn();
  }
  
  logoutUser(){
    gSignIn.signOut();
  }

  whenPageChanges(int pageIndex){
    setState(() {
      this.getPageIndex = pageIndex;
    });
  }

  onTapChangePage(int pageIndex){
    pageController.animateToPage(pageIndex, duration: Duration(milliseconds: 40), curve: Curves.easeInOut);
  }

  Scaffold buildHomeScreen(){
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          TimeLinePage(gCurrentUser: currentUser,),
          SearchPage(),
          UploadPage(gCurrentUser: currentUser,),
          NotificationsPage(),
          ProfilePage(userProfileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: whenPageChanges,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: getPageIndex,
        onTap: onTapChangePage,
        backgroundColor: Colors.white,
        activeColor: Colors.black87,
        inactiveColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera, size: 37.0,)),
          BottomNavigationBarItem(icon: Icon(Icons.favorite)),
          BottomNavigationBarItem(icon: Icon(Icons.person)),
        ],
      ),
    );
  }

  Scaffold buildSignInScreen(){
    return Scaffold(
      body: Container(
        color: Colors.white70,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 200.0),
              child: Text("", style: TextStyle(color: Colors.lightBlue, fontSize: 20.0, fontWeight: FontWeight.bold),),
            ),
            Text(
              "SocialNetwork",
              style: TextStyle(fontSize: 70.0, color: Colors.lightBlue, fontFamily: "Signatra"),

            ),
            Padding(
              padding: EdgeInsets.only(top: 100.0),
              child: Text("", style: TextStyle(color: Colors.lightBlue, fontSize: 20.0, fontWeight: FontWeight.bold),),
            ),
            GestureDetector(
              onTap: loginUser,
              child: Container(
                width: 250.0,
                height: 65.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/google_signin_button.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 80.0),
              child: Text("created by Kamil Ilhaq", style: TextStyle(color: Colors.grey, fontSize: 20.0, fontWeight: FontWeight.bold),),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if(isSignedIn)
    {
      return buildHomeScreen();
    }
    else
    {
      return buildSignInScreen();
    }
  }
}
