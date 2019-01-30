import csv
import json

output_list = []
reader = csv.DictReader(open('nudgelist.csv'))
for x in reader:
  idea = x['UI Implementation']
  if idea == '[Not applicable]':
  	continue
  if idea == '':
  	continue
  output_list.append(idea)
print(json.dumps({'generic/spend_less_time': output_list}, indent=2))
