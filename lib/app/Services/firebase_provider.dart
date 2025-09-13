import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:get/get.dart';

class FirebaseProvider {
  FirebaseProvider._();

  static Future<UserCredential> loginUser(String email, String password) async {
    try {
      return await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw e;
    }
  }

  static Future<UserCredential> registerUser(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await FirebaseAuth.instance.signOut();

      return userCredential;
    } catch (e) {
      throw e;
    }
  }

  static Future<void> uploadData(
    Map<String, dynamic> map,
    String collectionName,
    String? docId,
  ) async {
    try {
      CollectionReference collectionReference = await FirebaseFirestore.instance
          .collection(collectionName);
      if (docId != null)
        await collectionReference.doc(docId).set(map);
      else
        await collectionReference.add(map);
    } catch (e) {
      throw e;
    }
  }

  static Future<void> uploadDataToSubCollection(
    Map<String, dynamic> map,

    String collectionName,
    String subCollectionName,
    String docId,
    String subCollectionDocId,
  ) async {
    try {
      CollectionReference collectionReference = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(docId)
          .collection(subCollectionName);
      await collectionReference.doc(subCollectionDocId).set(map);
    } catch (e) {
      throw e;
    }
  }

  // delete subCollection Deocument
  static Future<void> deleteSubCollectionDocument(
    String collectionName,
    String collectionDocId,
    String subCollectionName,
    String subCollectionDocId, // this is what to be deleted
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(collectionDocId)
          .collection(subCollectionName)
          .doc(subCollectionDocId)
          .delete();
    } on FirebaseException catch (e) {
      throw e;
    }
  }

  // get Data

  static Future<Map<String, dynamic>> getData(
    String collectionName,
    String docId,
  ) async {
    try {
      CollectionReference collectionReference = await FirebaseFirestore.instance
          .collection(collectionName);

      DocumentSnapshot documentSnapshot = await collectionReference
          .doc(docId)
          .get();

      if (documentSnapshot.exists) {
        return documentSnapshot.data() as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      throw e;
    }
  }

  // Fetch
  static Future<List<Map<String, dynamic>>> fetchData(
    String collectionName,
  ) async {
    print("Start fetchData");

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .get();

      print("Query completed");

      List<Map<String, dynamic>> dataList = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      //print("Data: $dataList");
      return dataList;
    } catch (e) {
      print("🔥 Firestore error: $e");
      return [];
    }
  }

  // Fetch a sub collection
  static Stream<List<Map<String, dynamic>>> fetchSubCollection(
    String collectionName,
    String docId,
    String subCollectionName, {
    String? orderByField,
    bool descending = false,
  }) {
    print("Start streamData");

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection(collectionName)
        .doc(docId)
        .collection(subCollectionName);

    // Apply ordering only if field is provided
    if (orderByField != null && orderByField.isNotEmpty) {
      print("I worked!");
      query = query.orderBy(orderByField, descending: descending);
    }

    return query.snapshots().map((querySnapshot) {
      print("Stream update received");
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Search Query

  /// Searches a Firestore collection by a given field.
  /// Supports 'startsWith' type search using `isGreaterThanOrEqualTo` and `isLessThan`.
  static Future<List<Map<String, dynamic>>> searchData({
    required String collectionPath,
    required String field,
    required String searchText,
  }) async {
    if (searchText.isEmpty) return [];

    final String endText =
        searchText.substring(0, searchText.length - 1) +
        String.fromCharCode(searchText.codeUnitAt(searchText.length - 1) + 1);

    final querySnapshot = await FirebaseFirestore.instance
        .collection(collectionPath)
        .where(field, isGreaterThanOrEqualTo: searchText)
        .where(field, isLessThan: endText)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  // Logout

  static Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAllNamed('login');
    } on FirebaseAuthException catch (e) {
      print(e.toString());
    }
  }

  static Future<String?> getDocumentIdByFieldOfSubCollection({
    required String collectionname,
    required String mainCollectionId,
    required String subCollectionPath,
    required String field,
    required dynamic value,
  }) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(collectionname)
          .doc(mainCollectionId)
          .collection(subCollectionPath)
          .where(field, isEqualTo: value)
          .limit(1) // only first match
          .get();

      if (snapshot.docs.isNotEmpty) {
        print(snapshot.docs.first.id);
        return snapshot.docs.first.id; // return document ID
      } else {
        print("Nothing there!");
        return null; // no match found
      }
    } catch (e) {
      print("🔥 Firestore error in getDocumentIdByField: $e");
      return null;
    }
  }

  // Check is a specific field value exists or not

  static Future<bool> checkFieldValueInSubcollection({
    required String parentCollection,
    required String parentDocId,
    required String subcollectionName,
    required String fieldName,
    required dynamic fieldValue,
  }) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(parentCollection)
          .doc(parentDocId)
          .collection(subcollectionName)
          .where(fieldName, isEqualTo: fieldValue)
          .limit(1) // stop early if found
          .get();
      print("Matching document data: ${querySnapshot.docs.first.data()}");

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking field value: $e");
      return false;
    }
  }

  static Stream<List<Map<String, dynamic>>>
  fetchMainCollectionDocumentsBasedOnFieldMatch(
    String collectionName,
    String field,
    String value,
  ) {
    print("Start streamData");

    return FirebaseFirestore.instance
        .collection(collectionName)
        .where(field, isEqualTo: value)
        .snapshots()
        .map((querySnapshot) {
          print("Stream update received");
          return querySnapshot.docs
              .map(
                (doc) => {
                  ...doc.data(),
                  "id": doc.id, // include doc ID for reference
                },
              )
              .toList();
        });
  }

  // Fetch main collection documents where an array field contains a value
  static Stream<List<Map<String, dynamic>>>
  fetchMainCollectionWhereArrayContains(
    String collectionName,
    String arrayField,
    dynamic value,
  ) {
    return FirebaseFirestore.instance
        .collection(collectionName)
        .where(arrayField, arrayContains: value)
        .snapshots()
        .map((querySnapshot) {
          return querySnapshot.docs
              .map((doc) => {...doc.data(), "id": doc.id})
              .toList();
        });
  }

  // Update main collection document Map Field
  static Future<void> updateMainCollectionDocumentMapAllFieldExceptOne(
    String collectionName,
    String documentId,
    String mapField,
    String mapKey,
    String mapValue,
  ) async {
    try {
      // document Reference
      final docRef = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(documentId);

      // document Snapshot
      final snapShot = await docRef.get();

      // extract data from snapShots as Map
      final data = snapShot.data() as Map<String, dynamic>;

      // now data have the whole document Data as Map, But we want a specific map from this data

      final myMap = Map<String, dynamic>.from(
        data[mapField],
      ); // this is local map

      // so update the local map
      myMap.updateAll((key, value) {
        return key == mapKey ? value : mapValue;
      });

      //update the firestore docReference with this local map

      docRef.update({mapField: myMap});

      //await docRef.update({"$mapField.$mapKey": mapValue});
      print("Done...");
    } catch (e) {
      print("Exception received ... : " + e.toString());
      throw e;
    }
  }

  // Update main collection document Map Field
  static Future<void> updateMainCollectionDocumentMapOneField(
    String collectionName,
    String documentId,
    String mapField,
    String mapKey,
    String mapValue,
  ) async {
    try {
      // document Reference
      final docRef = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(documentId);

      await docRef.update({"$mapField.$mapKey": mapValue});

      // // document Snapshot
      // final snapShot = await docRef.get();

      // // extract data from snapShots as Map
      // final data = snapShot.data() as Map<String, dynamic>;

      // // now data have the whole document Data as Map, But we want a specific map from this data

      // final myMap = Map<String, dynamic>.from(
      //   data[mapField],
      // ); // this is local map

      // //update the firestore docReference with this local map

      // docRef.update({mapField: myMap});

      //await docRef.update({"$mapField.$mapKey": mapValue});
      print("Done...");
    } catch (e) {
      print("Exception received ... : " + e.toString());
      throw e;
    }
  }

  static Future<void> updateMainCollectionDocumentField(
    String collectionName,
    String documentId,
    String field,
    String value,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(documentId)
          .update({field: value});
    } catch (e) {
      throw e;
    }
  }

  // get only one field of  main collection document

  static Future<String?> getFieldOfMainCollectionDocumentField(
    String collectionName,
    String fieldName,
    String docId,
  ) async {
    try {
      CollectionReference collectionReference = await FirebaseFirestore.instance
          .collection(collectionName);

      DocumentSnapshot documentSnapshot = await collectionReference
          .doc(docId)
          .get();

      if (documentSnapshot.exists) {
        Map data = documentSnapshot.data() as Map<String, dynamic>;

        return data[fieldName];
      } else {
        return null;
      }
    } catch (e) {
      throw e;
    }
  }
}
