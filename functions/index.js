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

exports.onUserDataUpdate = functions.firestore.document('users/{userId}')
    .onUpdate((change) => {
        //algolia
        const newData = change.after.data();
        const objectID = change.after.id;

        const algoliaData = {'Pseudo': data['Pseudo'], 'Username': data['Username']};

        return usersIndex.saveObject({...algoliaData, objectID});
    });

exports.onUserDataDelete = functions.firestore.document('users/{userId}')
    .onDelete(snapshot => {
        //algolia
        return usersIndex.deleteObject(snapshot.id);
    });

exports.addAllUsersDataToAlgolia = functions.https.onRequest((req, res) => {
    admin.firestore().collection("users").get().then((docs) => {
        var arr = [];
        docs.forEach((doc) => {
            let user = {'Pseudo': doc.data()['Pseudo'], 'Username': doc.data()['Username']};
            user.objectID = doc.id;

            arr.push(user);
        });

        return usersIndex.saveObjects(arr, function (err, content) {
            if (err) {
               console.log(err.stack);
            }
            res.status(200).send(content);
        });
    }).catch((err) => {
        return console.error(err);
    });
});

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });
