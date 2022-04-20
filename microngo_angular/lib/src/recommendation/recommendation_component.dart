import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import '../../app_component.dart';
import '../service/chat_service.dart';


@Component(
  selector: 'recommendation',
  styleUrls: const [],
  templateUrl: 'recommendation_component.html',
  directives: const [materialDirectives, coreDirectives, formDirectives],
  providers: const [materialProviders, ChatService],
)
class RecommendationComponent implements OnInit {
  @Input()
  int messageID;

  @Input()
  ChatService chatService;

  @Input()
  AppComponent appComponent;

  bool done = false;

  addToCandidates(){
    chatService.entity_new(
      chatService.currentPoll.entity_type,
      chatService.messageCache[messageID].text,
      chatService.messageCache[messageID].name,
      false);
    done = true;
  }

  @override
  ngOnInit() {
    
  }
}