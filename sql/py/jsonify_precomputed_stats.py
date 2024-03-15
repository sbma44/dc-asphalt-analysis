import sys, json, csv

out = []
with open(sys.argv[1]) as f:
    reader = csv.reader(f)
    for row in reader:
        new_row = []
        for val in row:
            if len(val.strip()) > 0:
                new_row.append(int(val))
            else:
                new_row.append(0)
        out.append(new_row)
print(json.dumps(out))