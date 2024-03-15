import json, csv, os.path, sys, re

writer = csv.writer(sys.stdout)
writer.writerow('lng lat name address city state zip'.split())

with open(os.path.join(os.path.abspath(''), 'data', 'asphalt_md.json')) as f:
    data = json.load(f)

for plant in data['response']:
    row = []
    for field in 'lng lat name address city state zip'.split():
        row.append(plant.get(field, ''))
    writer.writerow(row)

with open(os.path.join(os.path.abspath(''), 'data', 'asphalt_va.json')) as f:
    data = json.load(f)

re_addy = re.compile(r'(.*?),(.*?),?\s(VA|DC|MD)\,?\s(\d{5})')
for plant in data['markers']:

    # fix random inconsistencies
    plant['address'] = plant['address'].replace('Chester Virginia', 'Chester, VA')

    if 'Washington, DC' in plant['address']:
        continue
    row = []
    for field in 'lng lat title'.split():
        row.append(plant[field])
    if '<img' in row[2]:
        row[2] = ''
        row += ['', '', '', '']
    else:
        m_address = re_addy.match(plant['address'])
        if m_address:
            address, city, state, zip = m_address.groups()
            row += [x.strip() for x in m_address.groups()]
        else:
            row += ['', '', '', '']
    writer.writerow(row)