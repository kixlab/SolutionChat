import 'package:angular/angular.dart';
import 'package:http/browser_client.dart';
import 'package:microngo_angular/src/model/advice.dart';
import 'package:microngo_angular/src/model/command.dart';
import 'package:microngo_angular/src/model/message_action.dart';
import 'package:microngo_angular/src/model/topics.dart';
import 'package:phoenix/phoenix.dart';

import 'dart:html';
import 'dart:async';
import 'dart:convert';

String urlEncodedMap(Map data) {
  return data.keys.map((key) => "${Uri.encodeComponent(key)}=${Uri.encodeComponent(data[key])}").join("&");
}

String base64Encode(String string){
  var bytes = utf8.encode(string);
  var b64 = base64.encode(bytes);
  return b64;
}

class ChatMessageGroup {
  String kind;
  bool expanded = false;
  List<int> messages = [];

  List<int> getRecentMessages(int count){
    if (messages.length <= count){
      return messages;
    }else{
      return messages.skip(messages.length-count).toList();
    }
  }

  ChatMessageGroup(this.kind, this.messages){

  }
}

@Injectable()
class ChatService {
  static const String localStorageTokenInfoKey = "tokenInfo";
  final BrowserClient _http;
  static const String clientID = "ngo.micro.prototype.angular";
  static const String clientSecret = "";

  List<Advice> advices = <Advice>[];
  List<Advice> adviceHistories = <Advice>[];
  int advicesCapacity = 3;
  removeAdvice(Advice advice){
    advices.remove(advice);
  }
  useAdvice(Advice advice){
    log("advice clicked ${advice.message}");
    sendChatMessage(advice.message);
    
    if (advice.tokens.length == 1){
      advices.remove(advice);
    }
  }


  Map<int, List<MessageAction>> messageActions = <int, List<MessageAction>>{};
  Map<int, List<ManagedMessage>> messageFeedbacks = <int, List<ManagedMessage>>{};


  String locale = "ko";
  Map<String, Map<String, String> > langMap = {
    "Read the problem": {
      "ko": "문제 읽기"
    },
    "Find a cause":{
      "ko": "원인 찾기"
    },
    "Find a Evidence": {
      "ko": "증거 찾기"
    },
    "Are they concrete cause and evidence?": {
      "ko": "원인과 증거가 확실한가?"
    },
    "Find a Solution":{
      "ko": "해결책 찾기"
    },
    "Find a benefit of solution": {
      "ko": "해결책 장점 찾기"
    },
    "Find a limitation of the solution": {
      "ko": "해결책 단점 찾기"
    },
    "Do we have a valid solution?": {
      "ko": "우리가 유효한 해결책을 찾았는가?"
    },
    "What social movement action can we take?": {
      "ko": "어떠한 사회 행동을 취할 수 있을까?"
    },
    "Petition receiver name": {
      "ko": "청원받는사람 이름"
    },
    "Petition receiver's title": {
      "ko": "청원받는사람의 직함"
    },
    "Petition delivery method": {
      "ko": "청원서를 보낼 방법"
    },
    "Campaign catchphrase": {
      "ko": "캠페인 캐치프레이즈(표어)"
    },
    "Campaign channel":{
      "ko": "캠페인 채널"
    },
    "Click": {
      "ko": "클릭"
    },
    "Brainstorm": {
      "ko": "브레인스토밍"
    },
    "Vote": {
      "ko": "투표"
    },
    "There are no candidates": {
      "ko": "후보가 없습니다"
    },
    "Not voted yet": {
      "ko": "아직투표안함"
    },
    "Let's vote": {
      "ko": "투표합시다"
    },
    "How to add a candidate?": {
      "ko": "어떻게 후보를 추가하나요?"
    },
    "[Help] Brainstorming Mode": {
      "ko": "[도움말] 브레인스토밍 모드"
    },
    "1. Click the answer message": {
      "ko": "1. 답이 담긴 메세지를 클릭합니다"
    },
    "2. Fill candidates list": {
      "ko": "2. 후보로 추가합니다"
    },
    "3. Click the start vote mode": {
      "ko": "3. 투표합시다 버튼을 누릅니다"
    },
    "Close": {
      "ko": "닫기"
    },
    "vote to go": {
      "ko": "표 남음"
    },
    "votes to go": {
      "ko": "표 남음"
    },
    "Discussion Agenda": {
      "ko": "토론 의제"
    },
    "Problem": {
      "ko": "문제"
    },
    "Vote result": {
      "ko":  "투표 결과"
    },
    "#user joined the room": {
      "ko": "#user님이 접속하였습니다"
    },
    "#user left the room": {
      "ko": "#user님이 나갔습니다"
    },
    "Please add candidates - Click a chat message to add it": {
      "ko": "후보를 추가해주세요 - 메세지를 클릭하면 추가할 수 있습니다"
    },
    "Please vote on our candidates": {
      "ko": "투표해주세요"
    },
    "Click here to visit after survey link and get your reward!": {
      "ko": "여기를 클릭해서 서베이에 참가하시고 보상을 받아가세요"
    },
    "Promote to the candidates": {
      "ko": "후보로 추가"
    },
    "Candidate": {
      "ko": "후보"
    },
    "A candidate which have received #targetVoteCount or more votes will be accepted as our answer for our current question.": {
      "ko": "한 후보가 #targetVoteCount표 이상을 득표하면 정답으로 채택하고 다음으로 넘어갑니다."
    },
    "Vote is closed":{
      "ko": "이 투표는 종료되었습니다"
    },
    "Adding a candidate": {
      "ko": "후보 추가"
    },
    "Add": {
      "ko": "추가"
    },
    "Cancel": {
      "ko": "취소"
    }
  };
  
  String t(String plain, [Map<String, dynamic> data]){
    var result = plain;
    if (langMap.containsKey(plain)
        && (langMap[plain][locale] != null
        && langMap[plain][locale].isNotEmpty)){
      result = langMap[plain][locale];
    }
    if (data != null){
      data.forEach((k, v){
        result = result.replaceAll("\#${k}", v.toString());
      });
    }
    return result;
  }

  String roomTitle = "ChatToAction";
  String serverHost = "localhost:4000";
  String get serverHostUrl => "http://${serverHost}";
  String get serverSocketUrl => "ws://${serverHost}";
  bool get developMode{
    return window.location.port == "8080";
  }

  int roomID = 1;
  String currentToken;
  Storage localStorage = window.localStorage;

  String currentTopicName;
  Topics topics = new Topics();
  int topicPage = 0;

  List<String> moderatorTemplates = <String>["사례를 모아볼까요?"];
  int moderator_id;
  String moderator_name;
  bool amIModerator(){
    if (me == null || me.id == null){
      return false;
    }
    return moderator_id == me.id;
  }

  Map<String, DateTime> typing_stamp = <String, DateTime>{};

  bool enabled = true;
  List<String> voteModeVotes = <String>[];
  bool voteEnabled = false;
  bool voteOnly = false;
  List<String> activities = [];  

  List<Command> commands = <Command>[];
  parseCommands(List<Map> list){
    commands = list.map((e) => new Command()..readFromMap(e)).toList();
  }

  List<Goal> goals = <Goal>[];
  parseGoals(List<Map> list){
    goals = list.map((e) => new Goal()..readFromMap(e)).toList();
  }

  Map<String, int> lastKindIndexes = <String, int>{};
  int amILastOfTheKind(String kind, int id){
    if (kind == null) return -1;
    if (id == null) return -1;
    var idx = lastKindIndexes[kind];    
    if (idx == null || idx < id){
      lastKindIndexes[kind] = id;
      return id;
    }
    return idx;
  }

  Map<String, List<String>> promotes = <String, List<String>>{};

  List<Advice> uncompletedAdvices() {
    return advices.where( (a) => !a.kind.contains('-done') ).toList();
  }



  String shortUserName(String s){
    // var a = new RegExp(r"\b.").allMatches(s);
    // var b = a.map((match) => match.group(0).toUpperCase())
    //     .where((t) => t != "-")
    //     .join("");
    // return b;
    return s;
  }
  

  int room_level = 0;
  int target_members = 0;
  List<Member> slots(){
    List<Member> list = presence.toList();
    while (list.length < target_members){
      list.add(null);
    }
    return list;
  }
  DateTime start_at;
  bool started = false;
  bool inTutorial = false;

  String reward_code = "";

  int experimentMode = 0;

  bool isObserver = false;
  bool isLogined = false;
  bool isConnected = false;

  Member me = new Member(id: 1, username: "no_name");

  List<Member> presence = [];
  List<int> tutorial_done = [];

  String topicSentence = "";

  int targetVoteCount(){
    var a = (presence.length * 0.51).ceil();
    if (a < 2){
      return 2;
    }
    return a;
  }

  int voteCountByEntityAndPoll(int entityID, int pollID){
    var cnt = 0;

    cnt = voteListByEntity(entityID).fold<int>(0, (prev, e){
      if (e.poll_id == pollID){
        return prev + e.value;
      }
      return prev;
    });
    return cnt;
  }

  String consensusByPoll(Poll poll){
    if (poll == null) return null;

    var a = <ManagedEntity>[];
    entityCache.forEach( (k, v) {
      if ( (v.type == poll.entity_type)
          && v.parent == poll.entity_parent_id){
        a.add(v);
      }
    });
    a.sort((e1, e2){
      var e2VoteCnt = voteCountByEntityAndPoll(e2.id, poll.id);
      var e1VoteCnt = voteCountByEntityAndPoll(e1.id, poll.id);
      return e2VoteCnt - e1VoteCnt;
    });

    if (a.length > 0){
      return a.first.title;
    }else{
      return null;
    }
  }

  String consensusByEntityType(String entityType){
    if (currentPoll == null) return null;
    var entity = entityCache[currentPoll.entity_parent_id ];
    if (entity == null) return null;
    var matching = entity.rootTree()
        .map((id) => entityCache[ id ])
        .firstWhere((e) => e.type_name == entityType, orElse: () => null);
    if (matching == null) return null;
    return matching.title;
  }

  String currentAccept(){
    if (currentPoll == null) return null;
    return currentPoll.entity_type;
  }

  Map<int, ManagedMessage> messageCache = {};
  Map<int, ManagedEntity> entityCache = {};
  Map<int, ManagedVote> voteCache = {};
  Map<int, Poll> pollCache = {};

  Poll previousPoll;
  Poll currentPoll;
  List<ManagedEntity> pollRanks = [];

  StreamController<dynamic> _onAppendChatmessageCtrl = new StreamController<dynamic>.broadcast();
  Stream<dynamic> onAppendChatmessage() => _onAppendChatmessageCtrl.stream;

  StreamController<dynamic> _onResetClockCtrl = new StreamController<dynamic>.broadcast();
  Stream<dynamic> onResetClock() => _onResetClockCtrl.stream;

  String get_user_position_on_poll(int userID){
    if (currentPoll == null) return "Undecided";
    ManagedVote found;
    voteCache.forEach((k, v){
      if (v.poll_id == currentPoll.id && v.user_id == userID){
        found = v;
      }
    });
    if (found == null) return "Undecided";
    var entity = entityCache[found.entity_id];
    if (entity == null){
      return "Undecided";
    }else{
      return entity.title;
    }
  }

  List<ManagedEntity> updatePollRanks() {
    var a = <ManagedEntity>[];
    if (currentPoll == null) return a;
    entityCache.forEach( (k, v) {
      if ( (v.type == currentPoll.entity_type || v.type == "undecided" )
          && v.parent == currentPoll.entity_parent_id){
        a.add(v);
      }
    });
    a.sort((e1, e2){
      var e2VoteCnt = voteCountByEntity(e2.id);
      var e1VoteCnt = voteCountByEntity(e1.id);
      return e2VoteCnt - e1VoteCnt;
    });
    pollRanks = a;
    return a;
  }

  List<ManagedEntity> pollRanksByPollId(int id) {
    var poll = pollCache[id];
    var a = <ManagedEntity>[];
    if (id == null) return a;
    if (poll == null) return a;

    entityCache.forEach( (k, v) {
      if ( (v.type == poll.entity_type || v.type == "undecided" )
          && v.parent == poll.entity_parent_id){
        a.add(v);
      }
    });
    a.sort((e1, e2){
      var e2VoteCnt = voteCountByEntity(e2.id);
      var e1VoteCnt = voteCountByEntity(e1.id);
      return e2VoteCnt - e1VoteCnt;
    });
    return a;
  }


  List<String> voteMemberForEntity(int entityID){
    if (currentPoll == null) return [];

    return voteListByPoll(currentPoll.id)
        .where((t) => t.entity_id == entityID)
        .map((vote){
          var member = presence.firstWhere((member) => member.id == vote.user_id, orElse: () => null);
          if (member == null) return "UN";
          return member.username;
        }).toList();
  }


  List<String> voteMemberForNotVoted(){
    if (currentPoll == null) return [];

    var members = presence.toList();

    voteListByPoll(currentPoll.id)
        .forEach((vote){
          members.removeWhere((m) => m.id == vote.user_id);
        });

    return members.map((m) => m.username).toList();
  }


  int voteCountByEntity(int entityID){
    var cnt = 0;
    if (currentPoll == null) return cnt;
    cnt = voteListByEntity(entityID).fold<int>(0, (prev, e){
      if (e.poll_id == currentPoll.id){
        return prev + e.value;
      }
      return prev;
    });
    return cnt;
  }

  List<ManagedVote> voteListByEntity(int entityID){
    List<ManagedVote> a = [];
    voteCache.forEach((k,v){
      if (v.entity_id == entityID) a.add(v);
    });
    return a;
  }
  List<ManagedVote> voteListByPoll(int pollID){
    List<ManagedVote> a = [];
    voteCache.forEach((k,v){
      if (v.poll_id == pollID) a.add(v);
    });
    return a;
  }

  bool votedBy(int entity_id, int user_id){
    var result = false;
    if (currentPoll == null) return result;

    voteCache.forEach((k,v){
      if (v.poll_id == currentPoll.id && v.entity_id == entity_id && v.user_id == user_id){
        result = true;
      }
    });
    return result;
  }

  int messageLowestID;
  int messageHighestID;
  List<ManagedMessage> messageVisibles = [];

  Stream<dynamic> get onStateChanges => _onStateChangesCtrl.stream;
  StreamController<dynamic> _onStateChangesCtrl = new StreamController<dynamic>.broadcast();

  Stream<RoomState> get onRoomStatChanges => _onRoomStatChangesCtrl.stream;
  StreamController<RoomState> _onRoomStatChangesCtrl = new StreamController<RoomState>.broadcast();

  // StreamController<ChatMessage> _chatMessageStreamController = new StreamController<ChatMessage>();
  // Stream<ChatMessage> onMessageChange() => _chatMessageStreamController.stream;

  StreamController<bool> _chatFetchPreviousController = new StreamController<bool>();
  Stream<bool> onFetchPrevious() => _chatFetchPreviousController.stream;

  bool _fetchingPrevious = false;
  bool get fetchingPrevious => _fetchingPrevious;
  void set fetchingPrevious(bool val){
    _fetchingPrevious = val;
    _chatFetchPreviousController.add(val);
  }


  RoomState roomState;
  Socket socket;
  Channel statChannel;

  requestPreviousMessages(){
    fetchingPrevious = true;
    return statChannel.push("get_previous_messages", {
      "from_id": messageLowestID
    });
  }

  void activate(bool ignore){
    if (developMode == false){
      serverHost = window.location.host;
    }

    if (ignore == false){
      var storedToken = localStorage[roomID.toString()];
      if (storedToken != null){
        currentToken = storedToken;
      }
    }

    socket = new Socket("//${serverHost}/socket", {
      "params": {
        "user": "token"
      }
    });
    socket.connect();

    statChannel = socket.channel("stat:${this.roomID}", {});
    statChannel.join()
        .receive("ok", (map){
      print("stat-ok");
      isConnected = true;
      isLogined = false;
      sendLogin();
      
      if (messageCache.length == 0){
        requestPreviousMessages();
      }
      //sendRoomStatRequest();
    }).receive("timeout", (map){
      isConnected = false;
      print("timeout");
      print(map);
    }).receive("error", (map){
      isConnected = false;
      print("error");
      print(map);
    });

    statChannel.on("init").listen((map){
      print("server-side init");
      sendLogin();
    });

    statChannel.on("activity").listen((map){
      activities.add(map["message"]);
      while (activities.length > 5){
        activities.removeAt(0);
      }
    });

    statChannel.on("message").listen((map){
      print("message!!!!!");
      print(json.encode(map));
      _handleMessages(map);
    });

    statChannel.on("new_advice").listen((map){
      var a = new Advice.fromMap(map);
      if (a.kind.contains("-done")){
        var target = a.kind.replaceFirst("-done", "");
        List<Advice> deleting = [];
        advices.forEach((advice){
          if (advice.kind == target){
            advice.shift();
            if (advice.tokens.length == 0){
              deleting.add(advice);
            }
          }
        });
        deleting.forEach((advice){
          removeAdvice(advice);
        });
        // advices.removeWhere((e) => e.kind == target);
        advices.insert(0, new Advice.fromMap(map));
        while (advices.length > advicesCapacity){
          var removed = advices.removeLast();
          adviceHistories.removeWhere((e) => e.kind == removed.kind);
          adviceHistories.insert(0, removed);
        }
      }else{
        var adding = new Advice.fromMap(map);
        advices.removeWhere((e) => e.kind == adding.kind);
        advices.insert(0, adding);        
        while (advices.length > advicesCapacity){
          var removed = advices.removeLast();
          adviceHistories.removeWhere((e) => e.kind == removed.kind);
          adviceHistories.insert(0, removed);
        }
      }
    });

    statChannel.on("add_message_action").listen((map){
      var a = new MessageAction.fromMap(map);
      var b = messageActions[a.message_id] ?? <MessageAction>[];
      b.add(a);
      messageActions[a.message_id] = b;
    });

    statChannel.on("entities").listen((map){
      print("entities!!!!!");
      print(json.encode(map));
      if (map["entities"] != null){
        var a = (map["entities"] as List).cast<Map>();
        a.map((e) => new ManagedEntity.fromMap(this, e)).toList();
      }
      updatePollRanks();
    });

    statChannel.on("get_room_state").listen((map){
      print("get_room_state!!!!!");
      print(json.encode(map));

      roomTitle = map["room_title"] ?? "ChatToAction";
      room_level = map["room_level"] ?? 0;
      experimentMode = map["condition"] ?? 0;
      target_members = map["target_members"] ?? 0;
      started = map["started"];
      reward_code = map["reward_code"];
      inTutorial = map["in_tutorial"] ?? false;
      topicSentence = map["topic_sentence"] ?? "";
      enabled = map["enabled"] ?? true;
      
      if (experimentMode != 2){
        topicPage = map["topic_page"] ?? 0;
      }else if (topicPage == null){
        topicPage = 0;
      }

      if (map["start_count"] != null){
        start_at = new DateTime.now().add(new Duration(seconds: map["start_count"] as int));
      }

      if (map["tutorial_users"] != null){
        tutorial_done = (map["tutorial_users"] as List).cast<int>();
      }

      presence = [];
      var users = map["users"] as Map;
      users.forEach((k,v){
        presence.add(
          new Member(id: v["id"], username: v["username"])
        );
      });

      //엔티티 들
      var entities = map["entities"] as Map;
      entities.forEach((k,v){
        new ManagedEntity.fromMap(this, v);
      });

      //엔티티 셋
      var poll = map["poll"] as Map;
      if (poll == null){
        currentPoll = null;
      }else{
        currentPoll = new Poll.fromMap(poll);
      }

      var prevPoll = map["previous_poll"] as Map;
      if (prevPoll == null){
        previousPoll = null;
      }else{
        previousPoll = new Poll.fromMap(prevPoll);
      }

      var polls = map["polls"] as Map;
      pollCache = <int, Poll>{};
      polls.forEach((k,v){
        int id = int.tryParse(k);
        pollCache[id] = new Poll.fromMap(v);
      });

      //votes
      var votes = map["votes"] as Map;
      voteCache = {};
      votes.forEach((k,v){
        new ManagedVote.fromMap(this, v);
      });

      //commands
      if (map["commands"] != null){
        parseCommands((map["commands"] as List).cast<Map>());
      }

      //goals
      if (map["goals"] != null){
        parseGoals((map["goals"] as List).cast<Map>());
      }

      //promotes
      if (map["promotes"] != null){
        promotes.clear(); 
        var promMap = map["promotes"] as Map<String, dynamic>;
        promMap.forEach((k, v){
          var votes = (v as List).cast<String>();
          promotes[k] = votes;
        });
      }

      if (map["vote_mode_votes"] != null){
        voteModeVotes = (map["vote_mode_votes"] as List).cast<String>();
      }

      if (map["vote_enabled"] != null){
        voteEnabled = map["vote_enabled"];
      }

      if (map["vote_only"] != null){
        voteOnly = map["vote_only"];
      }

      if (map["topics"] != null){
        topics = new Topics()..fromMap(map["topics"]);
        if (currentTopicName != map["topics"]["current_topic_name"]){
          _onResetClockCtrl.add(true);
        }
        currentTopicName = map["topics"]["current_topic_name"] ?? "";
      }

      if (map["moderatorTemplates"] != null){
        moderatorTemplates = (map["moderatorTemplates"] as List).cast<String>();
      }else{
        moderatorTemplates = [];
      }

      moderator_id = map["moderator_id"]; 
      var a = presence.firstWhere((e) => e.id == moderator_id, orElse: () => null);
      moderator_name = a == null ? "N/A" : a.username;


      updatePollRanks();
      _onAppendChatmessageCtrl.add(null);
    });

    statChannel.on("votes").listen((map){
      var events = (map["vote_events"] as List).cast<Map<String, dynamic>>();
      for (var event in events){
        if (event["event"] == "deleted"){
          voteCache.remove(event["vote"]["id"]);
        }else{
          new ManagedVote.fromMap(this, event["vote"]);
        }
      }
      print(json.encode(events));
      updatePollRanks();
    });

    statChannel.on("typing").listen((map){
      typing_stamp[map["username"]] = new DateTime.now().add(new Duration(seconds: 2));
    });
  }

  ChatService(this._http){
    print("Spawn Service");
  }

  Push log(String text){
    return statChannel.push("log", {
     "text": text
    });
  }

  Push entity_new(String type, String title, String reference, [bool force = false]){
    return statChannel.push("entity_new", {
     "type": type,
     "title": title,
     "reference": reference,
     "force": force
    });
  }

  Push promote(String message){
    return statChannel.push("promote", {
     "message": message
    });
  }

  Push send_tutorial_done(){
    return statChannel.push("tutorial_done", {});
  }

  Push send_vote_mode_vote(bool state){
    return statChannel.push("vote_mode_vote", {
     "value": state
    });
  }

  Push new_topic_above(String from_name, String topic_name){
    return statChannel.push("new_topic_above", {
      "from_name": from_name,
      "topic_name": topic_name
    });
  }

  Push new_topic_below(String from_name, String topic_name){
    return statChannel.push("new_topic_below", {
      "from_name": from_name,
      "topic_name": topic_name
    });
  }

  Push add_an_answer_to_topic(String topic_name, String answer_name){
    return statChannel.push("add_an_answer_to_topic", {
      "topic_name": topic_name,
      "answer_name": answer_name
    });
  }

  Push start_voting_on_topic(String topic_name){
    return statChannel.push("start_voting_on_topic", {
      "topic_name": topic_name
    });
  }

  Push vote_on_answer(String topic_name, String answer_name, bool up){
    return statChannel.push("vote_on_answer", {
      "topic_name": topic_name,
      "answer_name": answer_name,
      "up": up
    });
  }

  Push mark_as_done(String topic_name){
    return statChannel.push("mark_as_done", {
      "topic_name": topic_name
    });
  }

  Push reopen(String topic_name){
    return statChannel.push("reopen", {
      "topic_name": topic_name
    });
  }

  Push focus(String topic_name){
    return statChannel.push("focus", {
      "topic_name": topic_name
    });
  }

  Push delete_answer(String topic_name, String answer_name){
    return statChannel.push("delete_answer", {
      "topic_name": topic_name,
      "answer_name": answer_name
    });
  }

  Push finish_discussion(){
    return statChannel.push("finish_discussion", {});
  }

  Push typing(){
    return statChannel.push("typing", {});
  }

  Push start(){
    return statChannel.push("start", {});
  }

  Push designate_moderator(int user_id){
    return statChannel.push("designate_moderator", {"user_id": user_id});
  }

  Push setEnabled(bool enabled){
    return statChannel.push("enabled", {"enabled": enabled});
  }
  
  _handleMessages(Map event){
    List<Map> chatMessagesMap = (event["messages"] as List).cast<Map>();
    if (chatMessagesMap.length == 0){
      return;
    }

    var a = chatMessagesMap.map((e) => new ManagedMessage.fromMap(this, e)).toList();

    int nowLowID =  messageLowestID;
    int nowHighID = messageHighestID;

    var inserts = <ManagedMessage>[];
    var adds = <ManagedMessage>[];

    if (nowLowID != null && a.last.id < nowLowID ){
      for (var message in a){
        if (message.parent != null){
          var a = messageFeedbacks[message.parent] ?? <ManagedMessage>[];
          a.add(message);
          messageFeedbacks[message.parent] = a;
          continue;
        }
        messageCache[message.id] = message;
        inserts.add(message);
        if (nowLowID == null || message.id < nowLowID ){
          nowLowID = message.id;
        };
        if (nowHighID == null || message.id > nowHighID ){
          nowHighID = message.id;
        };
        if (message.command != null){
          amILastOfTheKind(message.command, message.id);
        }
      }
    }else{
      for (var message in a){
        if (message.parent != null){
          var a = messageFeedbacks[message.parent] ?? <ManagedMessage>[];
          a.add(message);
          messageFeedbacks[message.parent] = a;
          continue;
        }
        if (nowHighID != null && messageCache[nowHighID].name == message.name && messageCache[nowHighID].kind == "normal"){
          message.visible = false;
        }
        messageCache[message.id] = message;
        adds.add(message);
        if (nowLowID == null || message.id < nowLowID ){
          nowLowID = message.id;
        };
        if (nowHighID == null || message.id > nowHighID ){
          nowHighID = message.id;
        };
        if (message.command != null){
          amILastOfTheKind(message.command, message.id);
        }
      }
    }

    if (inserts.length > 0){      
      fetchingPrevious = false;
      messageVisibles.insertAll(0, inserts);
    }
    if (adds.length > 0){
      if (messageVisibles.length == 0){
        fetchingPrevious = false;
      }
      messageVisibles.addAll(adds);
      _onAppendChatmessageCtrl.add(null);
    }

    messageLowestID = nowLowID;
    messageHighestID = nowHighID;
  }

  //Login

  Future<AccessToken> register(String email, String password, String nickname) async{
    if (email.isEmpty || password.isEmpty || nickname.isEmpty){
      throw "모든 항목을 입력해주셔야 합니다";
    }

    var paramMap = {
      "email": email,
      "password": password,
      "username": nickname,
    };

    var response = await _http.post(
      serverHostUrl + "/api/user/create",
      headers: {
        "Authorization": "Basic " + base64Encode(clientID + ":" + clientSecret),
        "Content-Type": "application/json"
      },
      body: json.encode(paramMap),
    );

    if (response.statusCode == 409){
      if (response.body.indexOf("_user_email_key") > -1){
        throw "해당 이메일로 이미 가입되어있습니다";
      }
      if (response.body.indexOf("_user_username_key") > -1){
        throw "해당 닉네임이 이미 존재합니다";
      }
    }else if (response.statusCode == 200){
//      var token = new AccessToken.fromMap(JSON.decode(response.body));
//      if (token != null) currentToken = token;
//
//      onTokenChanged();
        throw "registered";
        //return token;
    }else {
      throw "알 수 없는 에러";
    }

    return null; // make linter happy
  }


  Future<Null> sendLogin() async {
    if (currentToken == null){
      sendSignUp();
      return;
    };
    if (isObserver) return; 

    statChannel.push("login", {"token": currentToken})
    ..receive("ok", (map){
        print("ok");
        me = new Member(id: map["user_id"], username: map["username"]);
        print(json.encode(map));
        isLogined = true;
      })
      ..receive("error", (map){
        print("error");
        print(json.encode(map));
    });
  }

  Future<Null> sendSignUp() async {
    print("signup");
    statChannel.push("sign_up", {})
    ..receive("ok", (map){
      currentToken = map["token"];
      localStorage[roomID.toString()] = map["token"];
      sendLogin();
    });
  }

  void onTokenChanged(){
    if (currentToken == null) return;
    localStorage["tokenInfo"] = currentToken;

    if (isConnected == false) return; //여기에서부터는 채팅서버에 보고될 필요가 있는 것만
    sendLogin();
  }

  Future<String> doLogin(String id, String password) async {
    try{
      var response = await _http.post(
          serverHostUrl + "/api/user/token",
        headers: {
          "Authorization": "Basic " + base64Encode(clientID + ":" + clientSecret),
        }
      );

      if (response.statusCode == 200){
        Map map = json.decode(response.body);
        if (map["token"] != null){
          currentToken = map["token"];
          return currentToken;
        }else{
          throw "login failed";
        }
      }else{
        throw "login failed";
      }
    }catch(_){
      print("login failed");
    }
    return null; //to make linter happy;
  }

  sendChatMessage(String text, {int parent}){
    var payload = {
      "text": text,
      "parent": parent
    };
    statChannel.push("message_new", payload);
  }


  sendVote(int poll_id, int entity_id, int value){
    var payload = {
      "poll_id": poll_id,
      "entity_id" : entity_id,
      "value": value
    };
    statChannel.push("vote", payload);
  }
}


// class ChatMessage{
//   int id;
//   String kind;
//   String text;
//   String senderName;
//   DateTime stamp;
//   ChatService service;

//   ChatMessage(this.service, this.id, this.text, this.senderName, [this.stamp]);
//   ChatMessage.createFromMap(this.service, Map chatMessageMap){
//     this.id = chatMessageMap["id"];
//     this.kind = chatMessageMap["kind"];
//     this.text = chatMessageMap["text"];

//     this.senderName = chatMessageMap["senderName"];
//     this.stamp = DateTime.parse(chatMessageMap["stamp"]);
//   }
// }

class Member {
  int id;
  String email;
  String username;

  Member({this.id, this.username, this.email});
  Member.fromMap(Map map){
    this.id = map["id"];
    this.email = map["email"];
    this.username = map["username"];
  }
}

class AccessToken {
  String accessToken;
  String tokenType;
  int expiresIn;
  DateTime expiresBy;
  bool get expired => expiresBy.isBefore(new DateTime.now());

  AccessToken(this.accessToken, this.tokenType, this.expiresIn){
    this.expiresBy = new DateTime.now().add(new Duration(seconds: this.expiresIn));
  }

  AccessToken.fromMap(Map map){
    this.accessToken = map["access_token"];
    this.tokenType = map["token_type"];
    this.expiresIn = map["expires_in"];
    if (map["expires_by"] == null){
      //널인 경우 새로운 추가의 것이라고 생각하고 현재 시간에서 토큰 만기기간 추측하기
      this.expiresBy = new DateTime.now().add(new Duration(seconds: this.expiresIn));
    }else{
      this.expiresBy = DateTime.parse(map["expires_by"]);
    }
  }

  Map asMap(){
    var map = {};
    map["access_token"] = this.accessToken;
    map["token_type"] = this.tokenType;
    map["expires_in"] = this.expiresIn;
    map["expires_by"] = this.expiresBy.toIso8601String();
    return map;
  }
}

class RoomState {
  ChatService service;
  int id;
  String prompt;

  readFromMap(Map map){
    id = map["id"];
    prompt = map["prompt"];
  }

  RoomState.createFromMap(this.service, Map map){
    this.readFromMap(map);
  }
}

class ManagedMessage {
  ManagedMessage.newObj();
  int id;
  int parent;
  String kind;
  String name;
  String text;
  String localID;
  String votePosition = "Undecided";
  int entity_id;
  ChatService service;
  int poll_id;
  bool visible = true;
  String command;


  void readMap(Map map){
    id = map["id"];
    kind = map["kind"];
    name = map["name"];
    text = map["text"];
    localID = map["localID"];
    entity_id = map["entity_id"];
    votePosition = map["vote_position"];
    poll_id = map["poll_id"];
    command = map["command"];
    parent = map["parent"];
  }

  factory ManagedMessage.fromMap(ChatService service, Map map) {
    var a = new ManagedMessage.newObj();
    a.readMap(map);
    a.service = service;
    return a;
  }
}

class ManagedEntity {
  ChatService service;
  ManagedEntity.blank(this.service);
  int id;
  String type;
  String title;
  String reference_type;
  String reference;
  int voteCount = 0;
  int parent;

  String get type_name{

    return type;
//    switch (type) {
//      case 'problem':
//        return "문제";
//        break;
//      case 'cause':
//        return "원인";
//        break;
//      case 'evidence':
//        return "증거";
//        break;
//      case 'solution':
//        return "해결책";
//        break;
//      case 'pro':
//        return "장점";
//        break;
//      case 'con':
//        return "단점";
//        break;
//      case 'people_name':
//        return "청원수신인의 이름";
//        break;
//      case 'people_title':
//        return "청원수신인의 직함";
//        break;
//      case 'people_contact':
//        return "청원수신인의 연락처";
//        break;
//      case 'campaign_title':
//        return "캠페인문구";
//        break;
//      case 'campaign_channel':
//        return "캠페인채널";
//        break;
//      case 'debate_closed':
//        return "끝";
//        break;
//      default:
//        return "일반";
//    }

  }

  List<int> rootTree(){
    var rootTree = <int>[];
    var cursor = this.id;
    while (cursor != null){
      var obj = service.entityCache[cursor];
      if (obj == null) break;
      rootTree.insert(0, obj.id);
      cursor = obj.parent;
    }
    return rootTree;
  }

  void readMap(Map map){
    id = map["id"];
    type = map["type"];
    title = map["title"];
    reference_type = map["reference_type"];
    reference = map["reference"];
    parent = map["parent_id"];
  }

  factory ManagedEntity.fromMap(ChatService service, Map map) {
    var a = new ManagedEntity.blank(service);
    a.readMap(map);
    if (service.entityCache.containsKey(a.id)) {
      return service.entityCache[a.id];
    } else {
      service.entityCache[a.id] = a;
      return a;
    }
  }
}

class ManagedVote {
  ChatService service;

  ManagedVote.blank(this.service);

  int id;
  int poll_id;
  int entity_id;
  int user_id;
  int value;


  void readMap(Map map){
    id = map["id"];
    poll_id = map["poll_id"];
    entity_id = map["entity_id"];
    user_id = map["user_id"];
    value = map["value"];
  }

  factory ManagedVote.fromMap(ChatService service, Map map) {
    var a = new ManagedVote.blank(service);
    a.readMap(map);
    if (service.voteCache.containsKey(a.id)) {
      return service.voteCache[a.id];
    } else {
      service.voteCache[a.id] = a;
      return a;
    }
  }
}


class Poll {
  int id;
  String title;
  int room_id;
  String entity_type;
  int entity_parent_id;
  DateTime begin_at;
  DateTime end_at;

  void readMap(Map map){
    id = map["id"];
    title = map["title"];
    room_id = map["room_id"];
    entity_type = map["entity_type"];
    entity_parent_id = map["entity_parent_id"];
    begin_at = DateTime.parse( map["begin_at"] );
    end_at = DateTime.parse( map["end_at"] );
  }

  Poll.fromMap(Map map){
    readMap(map);
  }
}