import 'package:algolia/algolia.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:the_spot/services/database.dart';
import 'package:the_spot/services/library/userProfile.dart';
import 'package:the_spot/services/library/configuration.dart';
import 'package:the_spot/services/library/mapmarker.dart';
import 'package:the_spot/services/library/library.dart';

import 'algolia.dart';

Future<List<UserProfile>> searchUsers(
    BuildContext context, String query, Configuration configuration, int page) async {
  List<UserProfile> users = [];
  if (await checkConnection(context)) {
    try {
      final Algolia algolia = AlgoliaObject.algolia; //initiate algolia
      final firestore = Firestore.instance;

      if(page == -1)
        page = 0;

      AlgoliaQuery algoliaQuery = algolia.instance.index('users').search(query).setPage(page);
      AlgoliaQuerySnapshot algoliaQuerySnapshot =
          await algoliaQuery.getObjects();

      List<String> documentsId = [];
      algoliaQuerySnapshot.hits.forEach((result) {
        documentsId.add(result.objectID);
      });
      if (documentsId.length > 0) {
        await firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: documentsId)
            .getDocuments()
            .then((QuerySnapshot querySnapshot) {
          documentsId.forEach((element) {
            users.add(ConvertMapToUserProfile(querySnapshot.documents
                .firstWhere((document) => document.documentID == element)
                .data)); //returns documents in algolia order
            users[users.length - 1].userId = element;
          });

        }).catchError((err) {
          error(err.toString(), context);
          print(err);
        });
        users = await Database().isUsersFriendOrFollowed(context, users, configuration.userData.userId);
      }

    } catch (err) {
      error(err, context);
      print(err);
    }
  }
  return users;
}

Future<List<MapMarker>> searchSpots(BuildContext context,
    {String matchName}) async {
  List<MapMarker> spots = [];
  if (matchName != null && matchName != "") {
    spots = await Database().getSpots(context, matchName: matchName);
  } else {
    spots = await Database().getSpots(context);
  }

  return spots;
}
