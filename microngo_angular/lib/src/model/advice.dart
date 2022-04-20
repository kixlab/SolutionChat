class Advice {
  String title = "";
  String kind = "";
  String body = "";
  List<String> tokens = [];
  
  String get message {
    if (tokens.length > 0){
      return tokens.first;
    }else {
      return "";
    }
  }

  String shift(){
    if (tokens.length > 0){
      var a = tokens.first;
      tokens.removeAt(0);
      return a;
    }else {
      return "";
    }
  }

  bool sent = false;
  Advice.fromMap(Map map){
    kind = map["kind"];
    title = map["title"];
    body = map["body"];
    tokens = (map["message"] as String).split(new RegExp("[\?\.]"));
    tokens.removeWhere((e) => e.trim().isEmpty);
  }
}