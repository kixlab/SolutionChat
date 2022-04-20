import 'dart:html';
import 'package:angular/angular.dart';

@Directive(selector: '[tooltipAware]')
class ToolTipDirective {
  ToolTipDirective(Element el) {
    new Future.delayed(Duration(milliseconds: 300), (){
      if (el.offsetWidth < el.scrollWidth){
        el.classes.add("tooltip");
      }else{
        el.classes.removeWhere((e) => e == "tooltip");
      }
    });
  }
}
// let card = ".feedback-card" 개체
// if (card.offsetWidth > card.scrollWidth)
//   card.classList.add("tooltip");
