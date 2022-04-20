class MessageAction {
  int message_id;
  String kind = "";
  String title = "";
  bool used = false;

  MessageAction.fromMap(Map map){
    message_id = map["message_id"];
    kind = map["kind"];
    title = map["title"];
  }
}