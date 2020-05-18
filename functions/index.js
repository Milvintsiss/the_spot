const functions = require('firebase-functions');
const admin = require('firebase-admin');
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

exports.onUserDataDelete = functions.firestore.document('users/{userId}')
    .onDelete(snapshot => {
        //algolia
        return usersIndex.deleteObject(snapshot.id);
    });

exports.updateUserPseudoAndUsernameInAlgolia = functions.https.onCall((data, context) => {
    console.log(data);
    console.log(context.auth.uid);
    const algoliaData = data;
    const objectID = context.auth.uid;
    return usersIndex.saveObject({...algoliaData, objectID});
});


exports.sendFriendRequestNotificationTo = functions.https.onCall(async (data, context) => {
    console.log('Send friend request notification to ' + data['userId'] + ' from ' + data['pseudo']);
    let userDevicesTokens = [];
    await admin.firestore().collection('users').doc(data['userId']).get()
        .then((snapshot) => {
            return userDevicesTokens = snapshot.data()['DevicesTokens'];
        })
        .catch((err) => {
            return console.error(err);
        });
    return admin.messaging().sendToDevice(
        userDevicesTokens,
        {
            notification: {
                title: 'New friend request',
                body: data['pseudo'] + ` wants to add you as friend`,
                image: data['picturePath'],
                click_action: 'FLUTTER_NOTIFICATION_CLICK',

            },
            data: {
                'type': 'friendRequest',
                'userToAddId': context.auth.uid,
                'userPseudo': data['pseudo'],
                'picturePath': data['picturePath'],
                'mainUserId': data['userId']
            }
        }
    ).catch((err) => {
        return console.error(err);
    });
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
