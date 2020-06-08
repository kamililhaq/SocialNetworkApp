import 'package:kamililhaq/models/user.dart';
import 'package:kamililhaq/pages/HomePage.dart';
import 'package:kamililhaq/pages/ProfilePage.dart';
import 'package:kamililhaq/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}






class _SearchPageState extends State<SearchPage> with AutomaticKeepAliveClientMixin<SearchPage>
{
  TextEditingController searchTextEditingController = TextEditingController();
  Future<QuerySnapshot> futureSearchResults;

  emptyTheTextFormField(){
    searchTextEditingController.clear();
  }

  controlSearching(String str){
    Future<QuerySnapshot> allUsers = usersReference.where("username", isGreaterThanOrEqualTo: str).getDocuments();
    setState(() {
      futureSearchResults = allUsers;
    });
  }

  AppBar searchPageHeader(){
    return AppBar(
      backgroundColor: Colors.lightBlue,
      title: TextFormField(
        style: TextStyle(fontSize: 18.0, color: Colors.white,),
        controller: searchTextEditingController,
        decoration: InputDecoration(
          hintText: "Search here",
          hintStyle: TextStyle(color: Colors.white),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.lightBlue),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.lightBlue),
          ),
          filled: true,
          prefixIcon: Icon(Icons.person_pin, color: Colors.white, size: 30.0,),
          suffixIcon: IconButton(icon: Icon(Icons.clear, color: Colors.black,), onPressed: emptyTheTextFormField,)
        ),
        onFieldSubmitted: controlSearching,
      ),
    );
  }


  Container displayNoSearchResultScreen(){
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Icon(Icons.group, color: Colors.black, size: 50.0,)

          ],
        ),
      ),
    );
  }

  displayUsersFoundScreen(){
    return FutureBuilder(
      future: futureSearchResults,
      builder: (context, dataSnapshot)
      {
        if(!dataSnapshot.hasData)
        {
          return circularProgress();
        }

        List<UserResult> searchUsersResult = [];
        dataSnapshot.data.documents.forEach((document)
        {
          User eachUser = User.fromDocument(document);
          UserResult userResult = UserResult(eachUser);
          searchUsersResult.add(userResult);
        });

        return ListView(children: searchUsersResult);
      },
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: searchPageHeader(),
      body: futureSearchResults == null ? displayNoSearchResultScreen() : displayUsersFoundScreen(),
    );
  }
}





class UserResult extends StatelessWidget
{
  final User eachUser;
  UserResult(this.eachUser);


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(3.0),
      child: Container(
        color: Colors.white54,
        child: Column(
          children: <Widget>[
            GestureDetector(
              onTap: ()=> displayUserProfile(context, userProfileId: eachUser.id),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.black, backgroundImage: CachedNetworkImageProvider(eachUser.url),),  
                title: Text(eachUser.profileName, style: TextStyle(
                  color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.bold,
                ),),
                subtitle: Text(eachUser.username, style: TextStyle(
                  color: Colors.black, fontSize: 13.0,
                ),),
              ),
            ),
          ],
        ),
      ),
    );
  }


  displayUserProfile(BuildContext context, {String userProfileId})
  {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userProfileId: userProfileId)));
  }
}
