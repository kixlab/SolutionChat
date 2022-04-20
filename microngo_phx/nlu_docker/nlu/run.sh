echo "data change"
python3 -m snips_nlu generate-dataset ko data/dataset.yaml > dataset.json
echo "launching"
python3 api.py