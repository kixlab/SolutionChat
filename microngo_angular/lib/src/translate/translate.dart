class Translate {
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
}