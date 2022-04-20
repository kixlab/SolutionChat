import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:microngo_angular/src/model/command.dart';
import 'package:microngo_angular/src/model/message_action.dart';
import '../../app_component.dart';
import '../service/chat_service.dart';

@Component(
  selector: 'message',
  styleUrls: const ["message_component.css"],
  templateUrl: 'message_component.html',
  directives: const [materialDirectives, coreDirectives, formDirectives],
  providers: const [materialProviders, ChatService],
)
class MessageComponent implements OnInit {
  
  @Input()
  ManagedMessage message;

  @Input()
  ChatService chatService;

  @Input()
  AppComponent appComponent;

  bool isMyMessage = false;
  bool isModerator = false;

  bool replyVisible = false;
  var replyUsed = [false, false, false, false];

  show_reply() {
    if (replyVisible == true) return;
    replyVisible = true;
  }
  send_reply(replyIndex, replyMsg, message_id) {
    if (replyUsed[replyIndex]) return;
    
    replyUsed[replyIndex] = true;
    chatService.log("inline advice (manual) clicked ${replyMsg} for ${message.id}");
    chatService.sendChatMessage(replyMsg, parent: message_id);
  }

  List<MessageAction> messageActions() {
    var a = chatService.messageActions[message.id] ?? [];
    return a.where((e) => e.used == false).toList();
  }

  List<ManagedMessage> messageFeedbacks() {
    var a = chatService.messageFeedbacks[message.id] ?? [];
    return a;
  }

  takeAction(MessageAction action){
    chatService.log("inline advice (autosuggested) clicked ${action.title} for ${message.id}");
    chatService.sendChatMessage(action.title, parent: message.id);
    action.used = true;
  }

  @override
  ngOnInit() {
    if (chatService?.me?.username != null && message != null){
      isMyMessage = chatService.me.username == message.name;
    }
    if (chatService != null){
      var moderator = chatService.presence.firstWhere((e) => e.id == chatService.moderator_id, orElse: () => null);
      if (moderator != null){
        isModerator = moderator.username == message.name;
      }
    }
  }
}