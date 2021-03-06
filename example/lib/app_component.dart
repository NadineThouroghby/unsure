import 'dart:html';

import 'package:angular/angular.dart';
import 'package:dorker/dorker.dart';
import 'package:unsure_angular_dart/unsure_result_message.dart';

@Component(
  selector: 'unsure-calc',
  styleUrls: ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: [
    NgIf,
    NgClass,
  ],
)
class AppComponent implements OnInit {
  DorkerWorker _worker;

  String simpleResult = '';

  String histogram = '';

  bool showHistogram = true;

  bool showPercentiles = false;

  bool isComputing = false;

  String note = 'Write a formula and hit Enter, or press =.';

  String percentiles = '';

  @ViewChild('formula')
  InputElement formulaInput;

  String formulaString = '100 / 4~6';

  void add(String s) {
    _updateFormulaString();
    formulaString = '$formulaString$s';
  }

  void delete() {
    _updateFormulaString();
    if (formulaString.isEmpty) return;
    formulaString = formulaString.substring(0, formulaString.length - 1);
    while (formulaString.endsWith(' ')) {
      formulaString = formulaString.substring(0, formulaString.length - 1);
    }
  }

  @override
  void ngOnInit() {
    _worker = DorkerWorker(Worker('worker.dart.js'));
    _worker.onMessage.listen(_receiveResult);
    _extractHashIntoFormula(window.location.hash);
    formulaInput.focus();
  }

  /// Takes a URL hash and, if it contains a valid formula, extracts it
  /// into [formulaInput]
  void _extractHashIntoFormula(String urlHash) {
    final fIndex = urlHash.indexOf('f=');
    if (fIndex == -1) return;

    final startIndex = fIndex + 'f='.length;
    if (startIndex >= urlHash.length) return;

    var endIndex = urlHash.length;

    var andIndex = urlHash.indexOf('&', startIndex);
    if (andIndex != -1) {
      endIndex = andIndex;
    }

    final urlEncodedFormula = urlHash.substring(startIndex, endIndex);

    if (urlEncodedFormula.isEmpty) return;

    final formula = Uri.decodeComponent(urlEncodedFormula);
    formulaString = formula;
    formulaInput.value = formula;
    startComputation(formula);
  }

  void startComputation(String formula) {
    _worker.postMessage.add(formula);
    isComputing = true;
    note = 'Please wait...';
    histogram = '';
    percentiles = '';
  }

  void _receiveResult(Object data) {
    var result = BaseResultMessage.fromData(data);
    simpleResult = result.simpleResult;
    isComputing = false;
    if (result is FailureResultMessage) {
      note = 'There was a problem with your formula ${result.message}.';
      histogram = '';
      percentiles = '';
    } else if (result is InvalidResultMessage) {
      note = 'Most or all of the results of this computation '
          'were invalid values. '
          'It doesn\'t make sense to run statistics on this formula.';
      histogram = '';
      percentiles = '';
    } else if (result is StochasticResultMessage) {
      histogram = result.histogram;
      percentiles = result.percentiles;
      note = '';
    } else if (result is NonStochasticResultMessage) {
      note = 'Try to make some inputs a bit more unsure, '
          'such as writing 4~6 instead of 4.';
      histogram = '';
      percentiles = '';
    } else {
      throw ArgumentError('$result is not one of the messages we expect');
    }
  }

  void _updateFormulaString() {
    formulaString = formulaInput.value;
  }
}
