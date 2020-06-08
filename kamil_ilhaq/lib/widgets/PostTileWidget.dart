import 'package:kamililhaq/pages/PostScreenPage.dart';
import 'package:kamililhaq/widgets/PostWidget.dart';
import 'package:flutter/material.dart';

class PostTile extends StatelessWidget
{
  final Post post;

  PostTile(this.post);

  displayFullPost(context)
  {
    Navigator.push(context, MaterialPageRoute(builder: (context)=>PostScreenPage(postId: post.postId, userId: post.ownerId)));
  }
  

  @override
  Widget build(BuildContext context) {
    return GestureDetector
    (
      onTap: () => displayFullPost(context),
      child: Image.network(post.url),
    );
  }
}
