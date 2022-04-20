import io
import json
from snips_nlu import SnipsNLUEngine, load_resources

with io.open("data.json") as f:
    sample_dataset = json.load(f)
load_resources(u"en")
nlu_engine = SnipsNLUEngine()
nlu_engine.fit(sample_dataset)
parsing = nlu_engine.parse(u"What will be the weather in San Francisco next week?")
print(json.dumps(parsing, indent=2))
parsing = nlu_engine.parse(u"What will be the weather in San Francisco next week?")
print(json.dumps(parsing, indent=2))
parsing = nlu_engine.parse(u"What will be the weather in San Francisco next week?")
print(json.dumps(parsing, indent=2))
parsing = nlu_engine.parse(u"What will be the weather in San Francisco next week?")
print(json.dumps(parsing, indent=2))