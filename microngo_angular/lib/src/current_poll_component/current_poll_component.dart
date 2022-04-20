import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import '../../app_component.dart';
import '../service/chat_service.dart';



@Component(
  selector: 'current-poll',
  styleUrls: const ["current_poll_component.css"],
  templateUrl: 'current_poll_component.html',
  directives: const [materialDirectives, coreDirectives, formDirectives],
  providers: const [materialProviders, ChatService],
)
class CurrentPollComponent implements OnInit {
  @Input()
  ChatService chatService;
  @Input()
  AppComponent appComponent;

  bool helpBrainstormingVisible = false;

  bool get voteMode{
    if (chatService?.voteEnabled != null) return chatService.voteEnabled;
    return false;
  }

  bool hintVisible(){
    if (chatService.currentPoll == null) return false;
    return chatService.currentPoll.entity_type == "problem";
  }

  double percentOfTheVotes(int id){
    var voteSum = 0;
    var targetVote = 0;
    chatService.voteListByPoll(chatService.currentPoll.id).forEach((e){
      voteSum += e.value;
      if (id == e.entity_id){
        targetVote += e.value;
      }
    });
    if (voteSum == 0) return 0.0;
    return (targetVote / voteSum) * 100;
  }

  String voteShortText(int entityID){
    var short = chatService.targetVoteCount() - chatService.voteCountByEntity(entityID);
    if (short == 0 || short > 1){
      return "($short ${chatService.t("votes to go")})";
    }else{
      return "($short ${chatService.t("vote to go")})";
    }
  }

  voteModeClick(){
    var username = chatService.me?.username;
    if (username == null) return;
    var voteRequest = chatService.voteModeVotes.indexOf(username) == -1;
    chatService.send_vote_mode_vote(voteRequest);
    if (voteRequest){
      chatService.voteModeVotes.add(username);
    }else{
      chatService.voteModeVotes.removeWhere((e) => e == username);
    }
  }

  bool voteModeActive(){
    var username = chatService.me?.username;
    if (username == null) return false;
    
    return chatService.voteModeVotes.indexOf(username) > -1;
  }

  @override
  ngOnInit() {
    
  }

}