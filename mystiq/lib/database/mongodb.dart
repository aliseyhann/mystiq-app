import 'dart:developer';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:mystiq_fortune_app/database/constant.dart';

class MongoDatabase {
  static connect() async {
    var db = await Db.create(MONGO_URL);
    await db.open();
    inspect(db);

    var status = db.serverStatus();
    print(status);
  }
} 