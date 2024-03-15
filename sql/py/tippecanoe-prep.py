import csv, json, sys

with open(sys.argv[1]) as f:
    reader = csv.reader(f, delimiter='\t')

    for row in reader:
        data = {
            'address': row[0],
            'distance_m': round(float(row[1])),
            'res_type': row[2],
            'created': row[4],
            'lng': row[5],
            'lat': row[6]
        }
        if not len(row[3].strip()):
            data['res_count'] = None
        else:
            data['res_count'] = int(float(row[3]))

        feat = {
            "type": "Feature",
            "geometry": {
                "type": "Point",
                "coordinates": [float(data['lng']), float(data['lat'])]
            },
            "properties": {k: data[k] for k in data if k not in ('lng', 'lat')}
        }
        print(json.dumps(feat))
