import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:microngo_angular/src/model/topics.dart';
import 'package:microngo_angular/src/service/chat_service.dart';
import 'package:microngo_angular/src/translate/translate.dart';

@Component(
  selector: 'tutorial',
  styleUrls: const ['package:angular_components/css/mdc_web/card/mdc-card.scss.css', 'app_component.css'],
  templateUrl: 'tutorial_component.html',
  directives: const [materialDirectives, coreDirectives, formDirectives],
  providers: const [materialProviders],
)
class TutorialComponent implements OnInit{
  Translate translate = new Translate();
  List<ManagedMessage> messageVisibles = [];

  int spendMin = 0;
  String myName;
  String currentTopicName;
  bool moderatorMode;

  Topics topics = new Topics();
  
  TopicAnswer getAnswer(String topicName, String answerName){
    var topic = topics.data[topicName];
    if (topic == null) return null;
    var answer = topic.answers[answerName];
    if (answer == null) return null;
    return answer;
  }

  topicVote(String topicName, String answerName) {
    var topic = topics.data[topicName];
    var answers = topic.answers[answerName];
    if (answers.votes.indexOf(answerName) == -1){
      answers.votes.add(answerName);
    }else{
      answers.votes.removeWhere((e) => e == answerName);
    }
  }
  int topicVoteCount(String topicName, String answerName){
    var topic = topics.data[topicName];
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
    var topic = topics.data[topicName];
    if (topic == null) return false;
    return topic.completed;
  }
  bool topicVoting(String topicName){
    var topic = topics.data[topicName];
    if (topic == null) return false;
    return topic.voting;
  }
  bool isCurrentTopic(String topicName){
    return currentTopicName == topicName;
  }
  setCurrnetTopicExecute(String topicName){
    // focusModalVisible = false;
    // if (chatService.amIModerator() == false) return;
    // chatService.focus(topicName);
  }
  List<String> topicOpinions(String topicName){
    if (isCurrentTopic(topicName)){
      return topics.data[topicName].orders;
    }else if (topics.data[topicName].orders.length > 0) {
      return <String>[topics.data[topicName].orders.first];
    }else{
      return <String>[];
    }
  }

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
    // if (addTopicAboveMode){
    //   chatService.new_topic_above(addTopicParent, addTopicName);
    // }else{
    //   chatService.new_topic_below(addTopicParent, addTopicName);
    // }    
    // addTopicVisible = false;
  }

  bool addAnswerVisible = false;
  String addAnswerTo = "";
  String addAnswerValue = "";
  addAnswerExecute(){
    if (addAnswerValue.isEmpty) return;
    // chatService.add_an_answer_to_topic(chatService.currentTopicName, addAnswerValue);
    addAnswerValue = "";
    // addAnswerVisible = false;
  }

  topicCompletedExecute(String topicName){
    // chatService.mark_as_done(topicName);
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

  bool focusModalVisible = false;
  String focusTo = "";
  focusModalPopup(String input){
    if (moderatorMode == false){
      return;
    }
    focusTo = input;
    focusModalVisible = true;
  }

  topicBoxText(String topicName){
    var topic = topics.data[topicName];
    if (currentTopicName == topic.name) return "►";
    if (topic.completed) return "✔";
    return "";
  }

  String chatInputText = "";
  String chatInputHolder = "";
  void addMessage(){
    if (chatInputText.isEmpty) return;
    var obj = new ManagedMessage.newObj()
      ..kind = "normal"
      ..name = myName
      ..text = chatInputText
      ..localID = ""
      ..votePosition = "Undecided"
      ..visible = true;
    
    messageVisibles.add(obj);
    chatInputText = "";
  }

  @override
  void ngOnInit() {
    // TODO: implement ngOnInit    
  }
}