import csv

reader = csv.DictReader(open('nudgelist.csv'))
for x in reader:
  idea = x['UI Implementation']
  print(idea)
