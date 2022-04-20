// Copyright (c) 2017, S.-C. Lee. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:microngo_angular/src/comp/message_component.dart';
import 'package:microngo_angular/src/current_poll_component/current_poll_component.dart';
import 'package:microngo_angular/src/directives/tooltip_directive.dart';
import 'package:microngo_angular/src/model/advice.dart';
import 'package:microngo_angular/src/model/topics.dart';
import 'package:microngo_angular/src/recommendation/recommendation_component.dart';
import 'src/service/chat_service.dart';
import 'src/comp/chat_message_component.dart';

@Component(
  selector: 'my-app',
  styleUrls: const ['package:angular_components/css/mdc_web/card/mdc-card.scss.css', "app_component.css"],
  templateUrl: 'app_component.html',
  directives: const [materialDirectives, coreDirectives, formDirectives, ChatMessageComponent, CurrentPollComponent, RecommendationComponent, MessageComponent, ToolTipDirective, MaterialDropdownSelectComponent, MaterialSelectSearchboxComponent,],
  providers: const [materialProviders, ChatService],
)
class AppComponent implements OnInit, OnChanges, AfterViewChecked{
  int spendMin = 0;
  bool initDone = false;
  int get experimentMode => chatService?.experimentMode ?? 0;
  bool experimentModeVisible = false;
  bool questionModalVisible = false;

  final ChatService chatService;

  @ViewChild('agendaBar')
  ElementRef agendaBarDiv;

  @ViewChild('chatScrollDiv')
  DivElement chatScrollDiv;
  
  int beforeScrollTop = 0;
  int beforeScrollHeight = 0;

  scrollInfoSave(){
    beforeScrollTop = chatScrollDiv.scrollTop;
    beforeScrollHeight = chatScrollDiv.scrollHeight;
  }

  @ViewChild('tutorialDiv')
  DivElement tutorialDiv;
  
  bool scrollToBottomEnabled = true;
  bool loadingPreviousVisible = true;


  bool waitingModalVisible = true;
  tutorialPopup(){
    tutorial = 0;
    waitingModalVisible = true;
  }
  String waitingTimeText = "";

  bool observerMenuVisible = false;
  observerPopup(){
    if (isObserving()){
      observerMenuVisible = true;
    }
  }

  //Topic

  String getTopicPlaceholder(String topicName){
    var topic = chatService.topics.data[topicName];
    if (topic == null) return "";
    return topic.placeholder;
  }

  TopicAnswer getAnswer(String topicName, String answerName){
    var topic = chatService.topics.data[topicName];
    if (topic == null) return null;
    var answer = topic.answers[answerName];
    if (answer == null) return null;
    return answer;
  }

  topicVote(String topicName, String answerName) {
    var topic = chatService.topics.data[topicName];
    var answers = topic.answers[answerName];
    if (answers.votes.indexOf(chatService.me.username) == -1){
      chatService.vote_on_answer(topicName, answerName, true);
    }else{
      chatService.vote_on_answer(topicName, answerName, false);
    }
  }
  int topicVoteCount(String topicName, String answerName){
    var topic = chatService.topics.data[topicName];
    if (topic == null) return 0;
    var answer = topic.answers[answerName];
    if (answer == null) return 0;
    return answer.votes.length;
  }
  List<String> topicVotors(String topicName, String answerName){
    var answer = getAnswer(topicName, answerName);
    if (answer != null){
      return answer.votes;
    }
    return <String>[];
  }
  bool topicVotorIsMe(String topicName, String answerName, String userName){
    var votors = topicVotors(topicName, answerName);
    return votors.indexOf(userName) != -1;
  }
  bool topicDone(topicName){
    var topic = chatService.topics.data[topicName];
    if (topic == null) return false;
    return topic.completed;
  }
  bool topicVoting(String topicName){
    var topic = chatService.topics.data[topicName];
    if (topic == null) return false;
    return topic.voting;
  }
  bool topicAnswerTop(String topicName, String answerName){
    var topic = chatService.topics.data[topicName];
    if (topic.orders.length > 0){
      return topic.orders.first == answerName;
    }else{
      return false;
    }
  }

  bool isCurrentTopic(String topicName){
    return chatService.currentTopicName == topicName;
  }
  setCurrnetTopicExecute(String topicName){
    focusModalVisible = false;
    if (chatService.amIModerator() == false) return;
    if ((chatService.experimentMode == 1 || chatService.experimentMode == 3) == false) return;
    chatService.focus(topicName);
  }
  List<String> topicOpinions(String topicName){
    if (isCurrentTopic(topicName)){
      return chatService.topics.data[topicName].orders;
    }else if (chatService.topics.data[topicName].orders.length > 0) {
      return chatService.topics.data[topicName].orders;
      // return <String>[chatService.topics.data[topicName].orders.first];
    }else{
      return <String>[];
    }
  }

  List<String> topicPage(){
    var prevs = chatService.topics.orders.where((e){
      return chatService.topics.data[e].page == chatService.topicPage -1;
    }).toList();
    var nows = chatService.topics.orders.where((e){
      return chatService.topics.data[e].page == chatService.topicPage;
    }).toList();
    if (prevs.length > 0){
      nows.insert(0, prevs.last);
    }
    return nows;
  }

  setTopicPage(int page){
    chatService.topicPage = page;
  }

  saySpendMin(){
    chatService.sendChatMessage("이 토픽으로 ${spendMin}분째 토론 중입니다.");
  }

  String get totalTime {
    if (chatService.start_at == null) return "0분";
    var mins = DateTime.now().difference(chatService.start_at).inMinutes;
    return "${mins}분";
  }

  // modal 1. designate
  bool designateVisible = false;
  int selectedUser = null;

  show_designate(int user_id) {
    if (chatService.isObserver == false) return;
    designateVisible = true;
    selectedUser = user_id;
  }

  designate_moderator(){
    chatService.designate_moderator(selectedUser);
    designateVisible = false;
    selectedUser = null;
  }


  // modal 2. add topic

  String addTopicParent;
  bool addTopicAboveMode = true;
  bool addTopicVisible = false;
  String addTopicName = "";
  addTopicAbove(String topicName){
    addTopicAboveMode = true;
    addTopicName = "";
    addTopicParent = topicName;
    addTopicVisible = true;
  }
  addTopicBelow(String topicName){
    addTopicAboveMode = false;
    addTopicName = "";
    addTopicParent = topicName;
    addTopicVisible = true;
  }
  addTopicExecute(){
    if (addTopicAboveMode){
      chatService.new_topic_above(addTopicParent, addTopicName);
    }else{
      chatService.new_topic_below(addTopicParent, addTopicName);
    }    
    addTopicVisible = false;
  }
  
  bool addAnswerVisible = false;
  String addAnswerTo = "";
  String addAnswerValue = "";
  // addAnswerPopup(String answerTo){
  //   addAnswerTo = answerTo;
  //   addAnswerValue = "";
  //   addAnswerVisible = true;
  // }
  addAnswerExecute(){
    if (addAnswerValue.isEmpty) return;
    chatService.log("adding answer by manual input for ${addAnswerValue}");
    chatService.add_an_answer_to_topic(chatService.currentTopicName, addAnswerValue);
    addAnswerValue = "";
    // addAnswerVisible = false;
  }
  addAnswerByClick(String body){
    chatService.log("answer adding by clicking inline message click for ${body}");
    chatService.add_an_answer_to_topic(chatService.currentTopicName, body);
    // addAnswerVisible = false;
  }

  topicCompletedExecute(String topicName){
    chatService.mark_as_done(topicName);
    // var topic = chatService.topics.data[topicName];
    // topic.completed = true;

    // var idx = chatService.topics.orders.indexOf(topicName);
    // var remained = chatService.topics.orders.toList().skip(idx+1).firstWhere((e){
    //   return chatService.topics.data[e].completed == false;
    // }, orElse: () => null);
    // if (remained != null){
    //   setCurrnetTopicExecute(remained);
    // }
  }
  topicStartVoteExecute(String topicName){
    var topic = chatService.topics.data[topicName];
    chatService.start_voting_on_topic(topicName);
  }
  topicReopen(String topicName){
    chatService.reopen(topicName);
  }

  bool delTopicAnswerVisible = false;
  String delTopicAnswerSelected = "";
  delTopicAnswerPopup(){
    if (chatService.currentTopicName == null) return;
    if (chatService.currentTopicName.isEmpty) return;
    delTopicAnswerSelected = "";
    delTopicAnswerVisible = true;
  }
  delTopicAnswerExecute(){
    delTopicAnswerVisible = false;
    if (delTopicAnswerSelected == null) return;
    if (delTopicAnswerSelected.isEmpty) return;
    chatService.delete_answer(chatService.currentTopicName, delTopicAnswerSelected);
  }
  topicBoxText(String topicName){
    var topic = chatService.topics.data[topicName];
    if (chatService.currentTopicName == topic.name) return "►";
    if (topic.completed) return "✔";
    return "";
  }

  String votingRate(int votes, int total){
    if (total == 0) return "0%";
      
    return ((votes / total)*100).toStringAsFixed(2)+"%";
  }

  int calcTotal(int total) {
    var moderator = chatService.presence.firstWhere((e) => e.id == chatService.moderator_id, orElse: () => null);
    
    return (total > 1 && moderator != null) ? total - 1 : total;
  }

  promptBoxText(String message){
    if (message == "#summary#"){
      return "[토론 요약 보여주기]";
    }else if (message == "#vote#"){
      return "[투표창 보여주기]";
    } else {
      return message;
    }
  }

  String typingPresenceText = "";

  bool focusModalVisible = false;
  String focusTo = "";
  focusModalPopup(String input){
    if (chatService.amIModerator() == false){
      return;
    }
    focusTo = input;
    focusModalVisible = true;
  }


  AppComponent self() => this;

  checkboxText(String type){
    if (chatService.consensusByEntityType(type) != null) return "✔";
    if (chatService.currentAccept() == type) return "⮕";
    return "";
  }


  String usernameTranslator(String username){
    var moderator = chatService.presence.firstWhere((e) => e.id == chatService.moderator_id, orElse: () => null);
    if (moderator == null){
      return username;
    }
    if (moderator.username == username){
      return "사회";
    }
    return username;
  }

  ChangeDetectorRef changeDetectorRef;

  AppComponent(this.chatService, this.changeDetectorRef){

  }



  @override
  ngAfterViewChecked() {
   
  }

  // void agendaBarAttention(){
  //   var barDiv = agendaBarDiv.nativeElement as DivElement;
  //   barDiv.classes.remove("animated");
  //   barDiv.classes.remove("bounce");
  //   new Future.delayed(new Duration(milliseconds: 100), (){
  //     var barDiv = agendaBarDiv.nativeElement as DivElement;
  //     barDiv.classes.add("animated");
  //     barDiv.classes.add("bounce");
  //   });
  // }

  String chatInputText = "";
  String chatInputHolder = "";
  void addMessage(){
      if (chatInputText.isEmpty) return;
      chatService.sendChatMessage(chatInputText);
      chatInputText = "";
  }
  setChatMessage(String msg){
    chatInputText = msg;
  }

  String bookmarkChatID = "";  


  bool messageTagging = false;
  List<ManagedMessage> targetTagMessages = []; //TODO: Remove
  String get targetTagMessage {
    targetTagMessages.sort((m1, m2){
      return m1.id - m2.id;
    });
    return targetTagMessages.map((f)=> f.text).join(" ");
  }

  bool similarConfirmVisible = false;
  List<Map> similars = [];
  void cancelMessageTagging(){
    messageTagging = false;
    similarConfirmVisible = false;
  }

  entity_new_by_tag([bool force = false]){
    if (chatService.currentPoll == null){
      cancelMessageTagging();
      return;
    }
    var title = targetTagMessage;
    if (title.isEmpty) {
      cancelMessageTagging();
      return;
    }
    var contributors = new Set<String>();
    for (var msg in targetTagMessages){
      contributors.add(msg.name);
    }

    //TODO 챗방의 상황에 맞는 타입 설정
    var push = chatService.entity_new(chatService.currentPoll.entity_type, title, contributors.join(", "), force);
    push.receive("ok", (map){
      if (map.containsKey("similars")){
        similars = map["similars"];
        messageTagging = false;
        similarConfirmVisible = true;
      }else{
        cancelMessageTagging();
      }
      changeDetectorRef.detectChanges();
      print(json.encode(map));
    });
  }

  bool isScrollBottom(){
    return (chatScrollDiv.scrollHeight - chatScrollDiv.scrollTop - chatScrollDiv.offsetHeight).abs() <= 500;
  }
  bool scrollToBottom(){
    chatScrollDiv.scrollTop = chatScrollDiv.scrollHeight;
    return true;
  }
  delayedToScrollToBottom(){
    if (isScrollBottom()){
      new Future.delayed(new Duration(milliseconds: 1), () => scrollToBottom());
    }
  }

  oneTimeInit() async{
    if (initDone) return;
    initDone = true;

    chatService.onAppendChatmessage().listen((onData){
      if (scrollToBottomEnabled) delayedToScrollToBottom();
    });

    chatService.onFetchPrevious().listen((onData){
      new Future.delayed(new Duration(microseconds: 1), (){
        if (onData == true) return;
        var offset = chatScrollDiv.scrollHeight - beforeScrollHeight;
        if (chatScrollDiv.scrollTop == 0) {
          if (offset > 0){
            chatScrollDiv.scrollTop = chatScrollDiv.scrollTop + offset;
          }       
        }
      });
    });
    
    // new Timer.periodic(new Duration(seconds: 1), (timer){
    //   if (chatService == null) return;
    //   if (chatService.start_at == null) return;
    //   var secs = chatService.start_at.difference(new DateTime.now()).inSeconds;
    //   var min = (secs / 60).floor();
    //   var sec = secs - (min * 60);
    //   waitingTimeText = "${min} minutes ${sec} seconds left";

    //   if (waitingModalVisible == false){
    //     timer.cancel();
    //   }
    // });

    new Timer.periodic(new Duration(minutes: 1), (timer){
      spendMin += 1;
    });
    
    new Timer.periodic(new Duration(seconds: 1), (timer){
      List<String> typings = [];
      DateTime now = new DateTime.now();
      chatService.typing_stamp.forEach((k, v){
        if (now.isBefore(v)){
          typings.add(k);
        }
      });
      typings.removeWhere((e) => e == chatService.me?.username);

      if (typings.length == 0){
        typingPresenceText =  "";
      }
      else {
        var finalist = typings.map((e) => usernameTranslator(e)).toList();
        typingPresenceText = "${finalist.join(", ")} 님이 입력 중입니다";
      }
    });


    chatService.onResetClock().listen((onData){
      spendMin = 0;
    });

    if (chatService.developMode == false){
      chatService.serverHost = window.location.host;
    }

    var roomID = roomNumberString();
    if (roomID == null || roomID.isEmpty){
      print("room number error");
      //window.alert("The room number is not assigned");
    }else{
      chatService.roomID = int.parse(roomID);
      //chatService.currentToken = Uri.parse(window.location.href).queryParameters["token"];
      chatService.isObserver = isObserving();
      chatService.activate(paramIgnore() == "true"); 
    }

    chatScrollDiv.onScroll.listen((event){
      scrollToBottomEnabled = (chatScrollDiv.scrollHeight - chatScrollDiv.scrollTop - chatScrollDiv.offsetHeight).abs() <= 500;
      print("scroll to bottom" + scrollToBottomEnabled.toString());
    });
    
    chatScrollDiv.onScroll.listen( (event){
      if (chatScrollDiv.scrollTop == 0){
        print("fetching Previous");
        scrollInfoSave();
        chatService.requestPreviousMessages();
      }
    });

    chatService.onStateChanges.listen((map){
      changeDetectorRef.detectChanges();
    });

    singleSelectModel.changes.listen((changeRecord){
      if (singleSelectModel.selectedValues.length > 0){
        chatService.sendChatMessage(singleSelectModel.selectedValues.first.message);
        singleSelectModel.clear();
      }
    });
  }

  String voteShortMessage(int messageID){
    var short = chatService.targetVoteCount() - chatService.voteCountByEntity(chatService.messageCache[messageID].entity_id);
    if (short == 0 || short > 1){
      return "($short votes to go)";
    }else{
      return "($short vote to go)";
    }
  }

  addToCandiates(int messageID){
    chatService.entity_new(
      chatService.currentPoll.entity_type,
      chatService.messageCache[messageID].text,
      chatService.messageCache[messageID].name,
      false);
  }

  int tutorial = 0;
  bool tutorialAdderVisible = false;
  void tutorialNext(){
    // tutorial += 1;
    // return;
    if (chatService.amIModerator()){
      tutorial += 1;
      if (tutorial > 10){
        waitingModalVisible = false;
        tutorial = 0;
      }
    }else{
      tutorial += 1;
      if (tutorial > 6){
        waitingModalVisible = false;
        tutorial = 0;
      }
    }    
  }
  void tutorialPrev(){
    tutorial -= 1;
    if (tutorial < 0) tutorial = 0;
  }

  bool isSendingPetition(){
    return chatService.consensusByEntityType('action_type') == '청원서 보내기';
  }

  bool isOnlineCampaign(){
    return chatService.consensusByEntityType('action_type') == '온라인 캠페인 열기';
  }

  void onHowToVoteClick(){
    window.alert("This is an example image, Please click it on the left pannel");
  }

  void animate(){
    var elem = querySelector("#anim");
    var animation = elem.animate([{"left": "100px"}, {"left": "300px"}], 200);
    animation.play();
  }


  String identiconColor(String username){
    if (username == null) return "?";
    var colors = [
      "#353866",
      "#95cd85",
      "#4ec5ff",      
      "#a8886c",
      "#cabc76",
    ];

    var idx = chatService.presence.indexWhere((e) => e.username == username);
    if (idx == -1){
      return "#5d5e5f"; 
    }else{
      var colorSet = idx % colors.length;
      return colors.elementAt(colorSet); 
    }
  }


  @override
  ngOnInit() {
    print("ngInit");
    print(initDone.toString());
    oneTimeInit();
  }
  @override
  ngOnChanges(Map<String, SimpleChange> changes) {
    scrollToBottomEnabled = (chatScrollDiv.scrollHeight - chatScrollDiv.scrollTop - chatScrollDiv.offsetHeight).abs() <= 00;
    print(scrollToBottomEnabled);
    scrollInfoSave();
  }

  String paramIgnore(){
    return Uri.parse(window.location.href).queryParameters["ignore"];
  }

  String roomNumberString(){
    return Uri.parse(window.location.href).queryParameters["room"];
  }

  bool isObserving(){
    return Uri.parse(window.location.href).queryParameters["observe"] == "true";
  }

  void visitSurvey(){
    var role = "debater";
    if (chatService.amIModerator()){
      role = "moderator";
    }
    window.location.href = "${chatService.serverHostUrl}/after?room_id=${chatService.roomID}&name=${chatService.me.username}&role=$role";
  }

  var dropdownOptions = AdviceSelectionOptions([
      Advice.fromMap({
        "kind": "카인드",
        "title": "타이틀",
        "body": "보디",
        "message": "다른 의견은 없으신가요?"
      }),
      Advice.fromMap({
        "kind": "카인드",
        "title": "타이틀",
        "body": "보디",
        "message": "토론범위를 줄여서 토론해볼까요?"
      }),
      Advice.fromMap({
        "kind": "카인드",
        "title": "타이틀",
        "body": "보디",
        "message": "이제까지 나온 의견들에 대해 투표할까요?"
      }),
      Advice.fromMap({
        "kind": "카인드",
        "title": "타이틀",
        "body": "보디",
        "message": "이제 투표를 해볼까요?"
      }),
      Advice.fromMap({
        "kind": "카인드",
        "title": "타이틀",
        "body": "보디",
        "message": "이제 다음 순서로 갈까요?"
      }),
      Advice.fromMap({
        "kind": "카인드",
        "title": "타이틀",
        "body": "보디",
        "message": "모아진 의견이 너무 편향적이진 않는지 생각해봅시다."
      }),
      Advice.fromMap({
        "kind": "카인드",
        "title": "타이틀",
        "body": "보디",
        "message": "투표 후보로 등록된 의견에 대해 각각 증거를 찾아볼까요?"
      })
    ]);

   final SelectionModel<Advice> singleSelectModel =
      SelectionModel.single();

    ItemRenderer<Advice> adviceMenuRenderer =
      newCachingItemRenderer<Advice>(
          (advice) => "${advice.message}");
}

class AdviceSelectionOptions extends StringSelectionOptions<Advice>
    implements Selectable<Advice> {
  
  AdviceSelectionOptions(List<Advice> options)
      : super(options,
            toFilterableString: (Advice option) => option.message);
  AdviceSelectionOptions.withOptionGroups(List<OptionGroup> optionGroups)
      : super.withOptionGroups(optionGroups,
            toFilterableString: (Advice option) => option.message);
  @override
  SelectableOption getSelectable(Advice item) => SelectableOption.Selectable;
}