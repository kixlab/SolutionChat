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

with io.open("dataset.json") as f:
    dataset = json.load(f)

intents = dataset['intents']
intent_keys = intents.keys()

for intent_key in intent_keys:
    for obj in intents[intent_key]["utterances"]:
        if obj["data"]:
            for data in obj["data"]:
                if data["text"]:
                    data["text"] = tokenize(data["text"])


print(json.dumps(dataset))


nlu_engine = SnipsNLUEngine(config=CONFIG_KO)
nlu_engine.fit(dataset)

# config = NLUEngineConfig([ProbabilisticIntentParserConfig()])
# nlu_engine = SnipsNLUEngine(config)
# nlu_engine.fit(dataset)
app = Flask(__name__)

@app.route("/nlu")
def test():
    q = request.args.get('q')
    tokenized = tokenize(q)
    print(tokenized)
    parsing = nlu_engine.parse(tokenized)
    return jsonify(parsing)

if __name__ == '__main__':
    app.debug = False
    app.run(host = '0.0.0.0', port=5000)