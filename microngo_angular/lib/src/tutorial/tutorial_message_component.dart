// import 'dart:async';
// import 'package:angular/angular.dart';
// import 'package:angular_components/angular_components.dart';
// import 'package:angular_forms/angular_forms.dart';
// import 'package:microngo_angular/src/model/command.dart';
// import 'package:microngo_angular/src/tutorial/tutorial_component.dart';
// import '../../app_component.dart';
// import '../service/chat_service.dart';

// @Component(
//   selector: 'chat-message',
//   styleUrls: const ['chat_message_component.css'],
//   templateUrl: 'chat_message_component.html',
//   directives: const [materialDirectives, coreDirectives, formDirectives],
//   providers: const [materialProviders, ChatService],
// )
// class TutorialMessageComponent implements OnInit {
//   //[class.active]="message.poll_id == (chatService.previousPoll?.id ?? -1) && chatService.consensusByPoll( chatService.previousPoll ) == chatService.entityCache[ message.entity_id ]?.title">

//   @Input()
//   ManagedMessage message;

//   @Input()
//   TutorialComponent appComponent;


//   bool amICandidate(){
//     if (appComponent.currentTopicName == null) return false;
//     if (appComponent.currentTopicName == "") return false;      

//     var msg = message;
//     return appComponent.topics.data[appComponent.currentTopicName]?.answers[msg.text] != null;
//   }

//   bool actionVisible = false;

//   bool get okToAddEntity {
//     return true;
//   }

//   void mouseEnter(){
//     var msg = message;
//     if (msg.kind == "normal" && msg.name != "Bot" && okToAddEntity){
//       actionVisible = true;
//     }
//   }
//   void mouseLeave(){
//     var msg = message;
//     if (msg.kind == "normal"){
//       actionVisible = false;
//     }
//   }
//   void popupAdder(){
//     if (okToAddEntity == false) return;
//     var msg = message;
//     if (!(msg.kind == "normal" && msg.name != "Bot")) return;
//     messageTagging = true;
//   }


//   bool messageTagging = false;

//   // String message(){
//   //   var msg = message;
//   //   if (msg == null) return "";
//   //   if (msg.kind == "normal") return msg.text;
//   //   if (msg.kind == "entity" && entityExist() == true){
//   //     var entity = chatService.entityCache[ message.entity_id ]?.title ?? "";
//   //     return "New candidate is added (${entity})";
//   //   }
//   //   return msg.text;
//   // }


//   // bool isChecked(){
//   //   return appComponent.targetTagMessages.firstWhere((t) => t.id == messageID, orElse: () => null) != null;
//   // }

//   String shortUserName(String s){
//     // var a = new RegExp(r"\b.").allMatches(s);
//     // var b = a.map((match) => match.group(0).toUpperCase())
//     //     .where((t) => t != "-")
//     //     .join("");
//     // return b;
//     return s;
//   }

//   addToCandidates(){
//     if (okToAddEntity == false) return;
//     if (chatService.experimentMode == 2){
//       if (chatService.currentTopicName == null) return;
//       if ( chatService.topics.data[chatService.currentTopicName].completed == true ) return;
//       chatService.add_an_answer_to_topic(chatService.currentTopicName, message.text);
//       messageTagging = false;
//     }else{
//       var push = chatService.entity_new(
//       chatService.currentPoll.entity_type,
//       message.text,
//       message.name,
//       false);
//       push.receive("ok", (map){
//         messageTagging = false;
//         appComponent.changeDetectorRef.detectChanges();
//       });
//     }
//   }

//   bool full = false;

//   bool get isPollOpen {
//     if (message?.poll_id == null) return false;
//     if (chatService.currentPoll?.id == null) return false;
//     if (message?.poll_id == chatService.currentPoll?.id) return true;
//     return false;
//   }

//   List<EntityRank> pollRanks(){
//     var msg = chatService.entityCache[ message.entity_id ]?.title ?? "";
//     var poll_id = message.poll_id;
//     var ranks = chatService.pollRanksByPollId(poll_id);
//     if (ranks.length == 0) return [];
//     var cnt = 1;
//     if (full) return ranks.map((e) => new EntityRank(cnt++, e)).toList();

//     var ret = <EntityRank>[];
//     ret.add( new EntityRank(1, ranks.first)  );
//     var targetIdx = ranks.indexWhere((e) => e.title == msg);
//     if (targetIdx != -1 && ranks[targetIdx].title != ranks.first.title){
//       ret.add( new EntityRank(targetIdx+1, ranks[targetIdx]));
//     }
//     return ret;
//   }


  

//   bool entityExist() => message.entity_id != null;

//   String entityTitle(){
//     return chatService.entityCache[ message.entity_id ]?.title ?? "";
//   }

//   @override
//   ngOnInit() {
//     if (message.kind == "entity" && entityExist() == false){
//       full = true;
//     }
//     new Future.delayed(new Duration(seconds: 5), () => actionVisible = false);
//   }
// }



// class EntityRank {
//   int rank;
//   ManagedEntity entity;
//   EntityRank(this.rank, this.entity);
// }