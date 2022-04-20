import io
import json
from snips_nlu import SnipsNLUEngine, load_resources
from snips_nlu.pipeline.configs import NLUEngineConfig, \
    ProbabilisticIntentParserConfig, ProcessingUnitConfig
from snips_nlu.default_configs import CONFIG_KO
from flask import Flask, jsonify, request
import khaiii

api = khaiii.KhaiiiApi()
api.open()

def tokenize(msg):
    striped = msg.strip()
    if striped == "":
        return ""
    tokens = []
    res = ""
    for word in api.analyze(msg):
        for m in word.morphs:
            tokens.append(m.lex)
        morphs_str = ' + '.join([(m.lex + '/' + m.tag) for m in word.morphs])
        res +=  f'{word.lex}\t{morphs_str}\n'
    return " ".join(tokens)

load_resources(u"ko")

with io.open("data.json") as f:
    dataset = json.load(f)

# config = NLUEngineConfig([ProbabilisticIntentParserConfig()])
# nlu_engine = SnipsNLUEngine(config)
nlu_engine = SnipsNLUEngine(config=CONFIG_KO)
nlu_engine.fit(dataset)

# nlu_engine = SnipsNLUEngine()
# nlu_engine.fit(sample_dataset)
app = Flask(__name__)

@app.route("/nlu")
def test():
    q = request.args.get('q')
    parsing = nlu_engine.parse(tokenize(q))
    print(q)
    return jsonify(parsing)