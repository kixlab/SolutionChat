class Command {
  String message;
  String action;
  String action_text;
  int target;
  List<String> votes;

  readFromMap(Map map){
    message = map["message"];
    action = map["action"];
    action_text = map["action_text"];
    target = map["target"];
    votes = (map["votes"] as List).cast<String>();
  }
}

class Goal {
  String message;
  String action;
  int target;
  int current;

  readFromMap(Map map){
    message = map["message"];
    action = map["action"];
    target = map["target"];
    current = map["current"];
  }
}