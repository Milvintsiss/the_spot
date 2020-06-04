const functions = require('firebase-functions');
const admin = require('firebase-admin');
const FieldValue = require('firebase-admin').firestore.FieldValue;
const algoliasearch = require('algoliasearch');

const ALGOLIA_APP_ID = "D5GGEY9O41";
const ALGOLIA_ADMIN_KEY = "1c17aeb2e312ca05f0b9d4f1b4e32097";

const algoliaClient = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
const usersIndex = algoliaClient.initIndex('users');

admin.initializeApp(functions.config().firebase);

exports.onUserDataCreation = functions.firestore.document('users/{userId}')
    .onCreate(snapshot => {
        //algolia
        const data = snapshot.data();
        const objectID = snapshot.id;

        const algoliaData = {'Pseudo': data['Pseudo'], 'Username': data['Username']};

        return usersIndex.saveObject({...algoliaData, objectID});
    });

//exports.onUserDataUpdate = functions.firestore.document('users/{userId}')
//.onUpdate((change) => {
//        //algolia
//        const newData = change.after.data();
//        const objectID = change.after.id;
//
//        const algoliaData = {'Pseudo': newData['Pseudo'], 'Username': newData['Username']};
//
//        return usersIndex.saveObject({...algoliaData, objectID});
//    });

exports.deleteUser = functions.https.onCall(async (data, context) => {
    let id = context.auth.uid;
    console.log('Delete user: ' + id);

    //delete from algolia
    usersIndex.deleteObject(id);
    console.log(id + 'Deleted from algolia');

    //delete user following
    await admin.firestore().collection('users').doc(id).collection('Following').get()
        .then(async (snapshot) => {
            for await (const document of snapshot.docs) {
                await admin.firestore().collection('users').doc(document.id)
                    .update(
                        {'NumberOfFollowers': FieldValue.increment(-1)}
                    );
                await admin.firestore().collection('users').doc(document.id).collection('Followers')
                    .doc(id).delete();
            }
            return console.log('Following of ' + id + ' deleted');
        });

    // delete user followers
    await admin.firestore().collection('users').doc(id).collection('Followers').get()
        .then(async (snapshot) => {
            for await (const document of snapshot.docs) {
                await admin.firestore().collection('users').doc(document.id)
                    .update(
                        {'NumberOfFollowing': FieldValue.increment(-1)}
                    );
                await admin.firestore().collection('users').doc(document.id).collection('Following')
                    .doc(id).delete();
            }
            return console.log('Followers of ' + id + ' deleted');
        });
    //delete user friends
    await admin.firestore().collection('users').doc(id).get()
        .then(async (snapshot) => {
            let friends = snapshot.data()['Friends'];
            if (friends !== undefined) {
                for await (const friend of friends) {
                    await admin.firestore().collection('users').doc(friend)
                        .update(
                            {
                                'Friends': FieldValue.arrayRemove(id),
                                'NumberOfFriends': FieldValue.increment(-1)
                            }
                        );
                }
            }
            return console.log('Friends of ' + id + ' deleted');
        });

    //delete pending friends
    await admin.firestore().collection('users').where('PendingFriendsId', "array-contains", id)
        .get()
        .then(async (snapshot) => {
            for await (const document of snapshot.docs) {
                await admin.firestore().collection('users').doc(document.id)
                    .update({'PendingFriendsId': FieldValue.arrayRemove(id)});
            }
            return console.log('PendingFriends of ' + id + ' deleted');
        });


    //delete user profile picture
    await admin.storage().bucket().file('ProfilePictures/' + id).delete().then(() => {
        return console.log('Profile picture of ' + id + ' deleted');
    }).catch((err) => {
        console.log(err);
    });

    //delete user message ///WARN\\\ delete archived messages when this will be implemented
    await admin.firestore().collection('groupChats')
        .where('MembersIds', "array-contains", id)
        .get()
        .then(async (snapshot) => {
            for await (const document of snapshot.docs) {
                let messagesArray = [];
                let isGroup;
                await admin.firestore().collection('groupChats').doc(document.id)
                    .get()
                    .then((data) => {
                            data.data()['Messages'].forEach((message) => {
                                if (message['SenderId'] === id) {
                                    messagesArray.push(message);
                                }
                            })
                            isGroup = data.data()['MembersIds'].length > 2;
                            return true;
                        }
                    );
                if (isGroup) {
                    console.log(messagesArray);
                    if (messagesArray.length > 0)
                        await admin.firestore().collection('groupChats').doc(document.id)
                            .update({
                                'MembersIds': FieldValue.arrayRemove(id),
                                'AdminsIds': FieldValue.arrayRemove(id),
                                'Messages': FieldValue.arrayRemove(...messagesArray),
                            });
                    else
                        await admin.firestore().collection('groupChats').doc(document.id)
                            .update({
                                'MembersIds': FieldValue.arrayRemove(id),
                                'AdminsIds': FieldValue.arrayRemove(id),
                            });
                } else
                    await admin.firestore().collection('groupChats').doc(document.id)
                        .delete();
            }
            return console.log('Messages of ' + id + ' deleted');
        });

    //delete userData
    await admin.firestore().collection('users').doc(id).collection('Followers').get()
        .then(async (snapshot) => {
            for await (const document of snapshot.docs) {
                await admin.firestore().collection('users').doc(id).collection('Followers')
                    .doc(document.id).delete();
            }
            return console.log('Followers collection of ' + id + 'deleted');
        })
    await admin.firestore().collection('users').doc(id).collection('Following').get()
        .then(async (snapshot) => {
            for await (const document of snapshot.docs) {
                await admin.firestore().collection('users').doc(id).collection('Following')
                    .doc(document.id).delete();
            }
            return console.log('Following collection of ' + id + 'deleted');
        })
    await admin.firestore().collection('users').doc(id)
        .delete()
        .catch((err) => {
            return console.error(err);
        });
    console.log(id + ' data deleted');

    //delete from auth
    await admin.auth().deleteUser(id);
    return console.log(id + ' deleted');
});

exports.updateUserPseudoAndUsernameInAlgolia = functions.https.onCall((data, context) => {
    console.log(data);
    console.log(context.auth.uid);
    const algoliaData = data;
    const objectID = context.auth.uid;
    return usersIndex.saveObject({...algoliaData, objectID});
});


exports.sendFriendRequestNotificationTo = functions.https.onCall((data, context) => {
    const title = data['title'];
    const body = data['body'];
    const userToAddAsFriendId = data['userToAddAsFriendId'];
    const mainUserId = data['mainUserId'];
    const mainUserPseudo = data['mainUserPseudo'];
    const mainUserProfilePictureDownloadPath = data['mainUserProfilePictureDownloadPath'];
    const mainUserProfilePictureHash = data['mainUserProfilePictureHash'];
    const userToAddTokens = data['userToAddTokens'];
    console.log('Send friend request notification to ' + userToAddAsFriendId + ' from ' + mainUserPseudo);

    return admin.messaging().sendToDevice(
        userToAddTokens,
        {
            notification: {
                title: title,
                body: body,
                image: mainUserProfilePictureDownloadPath,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            data: {
                'type': 'friendRequest',
                'userToAddId': mainUserId,
                'userPseudo': mainUserPseudo,
                'mainUserProfilePictureDownloadPath': mainUserProfilePictureDownloadPath,
                'mainUserProfilePictureHash': mainUserProfilePictureHash,
                'mainUserId': userToAddAsFriendId,
            }
        }
    )
});

exports.sendMessageNotificationTo = functions.https.onCall((data, context) => {
    const conversationId = data['conversationId'];
    const conversationName = data['conversationName'];
    const conversationPictureDownloadPath = data['conversationPictureDownloadPath'];
    const conversationPictureHash = data['conversationPictureHash'];
    const usersTokens = data['usersTokens'];
    const usersIds = data['usersIds']; //string containing ids in format "id/id/id/id/..."
    const message = data['message'];
    const senderPseudo = data['senderPseudo'];

    return admin.messaging().sendToDevice(
        usersTokens,
        {
            notification: {
                title: conversationName,
                body: senderPseudo + ": " + message,
                image: conversationPictureDownloadPath,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            data: {
                'type': 'message',
                'message': message,
                'senderPseudo': senderPseudo,
                'conversationId': conversationId,
                'conversationName': conversationName,
                'conversationPictureDownloadPath': conversationPictureDownloadPath,
                'conversationPictureHash': conversationPictureHash,
                'usersIds': usersIds,
            }
        }
    )
});


exports.repairCountFollowingFollowers = functions.https.onRequest((req, res) => {
    admin.firestore().collection('users').get()
        .then((docs) => {
            return docs.docs.forEach((doc) => {
                admin.firestore().collection('users').doc(doc.id).collection('Following').get()
                    .then((docs) => {
                        return admin.firestore().collection('users').doc(doc.id).update({'NumberOfFollowing': docs.size}).catch((err) => {
                            return console.error(err);
                        });
                    }).catch((err) => {
                    return console.error(err);
                });
                admin.firestore().collection('users').doc(doc.id).collection('Followers').get()
                    .then((docs) => {
                        return admin.firestore().collection('users').doc(doc.id).update({'NumberOfFollowers': docs.size}).catch((err) => {
                            return console.error(err);
                        });
                    }).catch((err) => {
                    return console.error(err);
                });
                return admin.firestore().collection('users').doc(doc.id).get()
                    .then((doc) => {
                        return admin.firestore().collection('users').doc(doc.id).update({'NumberOfFriends': doc.data()['Friends'].length}).catch((err) => {
                            return console.error(err);
                        });
                    }).catch((err) => {
                        return console.error(err);
                    });
            })
        }).catch((err) => {
        return console.error(err);
    });
});

exports.addAllUsersDataToAlgolia = functions.https.onRequest((req, res) => {
    return admin.firestore().collection("users").get().then((docs) => {
        let arr = [];
        docs.forEach((doc) => {
            let user = {'Pseudo': doc.data()['Pseudo'], 'Username': doc.data()['Username']};
            user.objectID = doc.id;

            arr.push(user);
        });

        return usersIndex.saveObjects(arr, (err, content) => {
            if (err) {
                console.log(err.stack);
            }
            res.status(200).send(content);
        });
    }).catch((err) => {
        return console.error(err);
    });
});

exports.repairDatabase = functions.pubsub.schedule('every 24 hours').onRun((context) => {

//get all spots collection, if spots are not initialized (missing SpotName value), erase them.
    return admin.firestore().collection("spots").get().then((docs) => {
        return docs.forEach((doc) => {
            if (!("SpotName" in doc.data())) {
                // eslint-disable-next-line promise/no-nesting
                admin.firestore().collection("spots").doc(doc.id).delete()
                    .then(() => {
                        return console.log("Document deleted:", doc.id);
                    })
                    .catch((err) => {
                        return console.error(err);
                    });
            }
        });
    }).catch((err) => {
        return console.error(err);
    });

//get all users followers and following and update numbers of following and followers
});

exports.addPropertyToUserProfile = functions.https.onRequest((req, res) => {
    return admin.firestore().collection("users").get().then((docs) => {
        return docs.forEach((doc) => {
            // eslint-disable-next-line promise/no-nesting
            admin.firestore().collection("users").doc(doc.id)
                .update({'AcceptNoFriendMessages': true})
                .then(() => {
                    return console.log("Success:", doc.id);
                })
                .catch((err) => {
                    return console.error(err);
                });
        });
    }).catch((err) => {
        return console.error(err);
    });
});

exports.changeUserStringISODates_toTimestamp = functions.https.onRequest((req, res) => {
    return admin.firestore().collection("users").get().then((docs) => {
        return docs.forEach((doc) => {
            const creationDate = doc.data()['CreationDate'];
            const updateDate = doc.data()['LastUpdate'];
            const _creationDate = parseISOString(creationDate);
            const _updateDate = parseISOString(updateDate);
            // eslint-disable-next-line promise/no-nesting
            admin.firestore().collection("users").doc(doc.id)
                .update({'CreationDate': _creationDate, 'LastUpdate': _updateDate})
                .then(() => {
                    return console.log("Success:", doc.id);
                })
                .catch((err) => {
                    return console.error(err);
                });
        });
    }).catch((err) => {
        return console.error(err);
    });
});

function parseISOString(date) {
    const b = date.split(/\D+/);
    return new Date(Date.UTC(b[0], --b[1], b[2], b[3], b[4], b[5], b[6]));
}


// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });
