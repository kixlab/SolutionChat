class TopicAnswer {
  String name;
  List<String> votes = [];
  TopicAnswer([this.name]);

  fromMap(Map map){
    name = map["name"];
    votes = ((map["votes"] ?? []) as List).cast<String>();
  }
}

class Topic {
  bool completed = false;
  bool voting = false;
  String name;
  int page = 0;
  String placeholder;
  Map<String, TopicAnswer> answers = {};
  List<String> orders = [];
  Topic([this.name]);

  fromMap(Map map){
    completed = map["completed"] ?? false;
    voting = map["voting"] ?? false;
    name = map["name"] ?? "";
    page = map["page"] ?? 0;
    placeholder = map["placeholder"] ?? "";

    answers = (map["answers"] as Map<String, dynamic>).map((k, v){
      return new MapEntry(k, new TopicAnswer()..fromMap(v)  );
    });
    orders = (map["orders"] as List).cast<String>();
  }
}

class Topics {
  Map<String, Topic> data = {};
  List<String> orders = [];

  fromMap(Map map){
    data = (map["data"] as Map<String, dynamic>).map((k, v){
      return new MapEntry(k, new Topic()..fromMap(v)  );
    });
    
    orders = (map["orders"] as List).cast<String>();
  }
}