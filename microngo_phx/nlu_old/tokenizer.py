import os
import glob 
import json
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


def tokenize_file(filename):
    print(filename)
    lines = []
    f = open(filename, "r")
    for x in f:
        lines.append(tokenize(x))
    a = os.path.basename(filename)
    filen = os.path.splitext(a)[0]
    w = open("backend_data/intents/"+filen+".txt", 'w')
    for x in lines:
        w.write(x + "\n")
    w.close()

filenames = glob.glob("data/intents/*.txt")
for filename in filenames:
    tokenize_file(filename)