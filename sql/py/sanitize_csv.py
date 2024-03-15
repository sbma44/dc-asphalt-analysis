import sys
import re
import csv

def validate_int(value):
    return re.match(r'^\d*$', value)

def validate_decimal(value):
    return len(value.strip()) == 0 or (re.match(r'^\-?\d+(\.\d+)?$', value))

def validate_text(value):
    # For this simple script, all non-empty values are considered valid text.
    return True

def validate_boolean(value):
    return value in ['Y', 'N']

def validate_timestamp(value):
    return len(value.strip()) == 0 or (re.match(r'^\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2}:\d{2}$', value))

def process_line(writer, headers, line):
    validators = {
        'int': validate_int,
        'decimal': validate_decimal,
        'text': validate_text,
        'boolean': validate_boolean,
        'timestamp': validate_timestamp,
    }

    field_types = [
        'int', 'decimal', 'text', 'int', 'text', 'text', 'text', 'text',
        'decimal', 'text', 'text', 'text', 'decimal', 'decimal', 'decimal',
        'decimal', 'text', 'text', 'text', 'text', 'text', 'text', 'decimal',
        'text', 'boolean', 'boolean', 'boolean', 'boolean', 'text', 'text',
        'text', 'text', 'text', 'text', 'text', 'text', 'text', 'decimal',
        'decimal', 'timestamp', 'text', 'timestamp', 'text', 'timestamp',
        'text', 'timestamp', 'text', 'timestamp', 'text', 'text', 'text',
        'text', 'text'
    ]
    field_types[37] = 'text' # MULTIPLE_LAND_SSL
    field_types[38] = 'text' # GRID_DIRECTION
    field_types[39] = 'decimal' # HOUSING_UNIT_COUNT

    # for i in range(max(len(headers), len(field_types))):
    #     sys.stderr.write(f'{i}: {headers[i]} ({field_types[i]})\n')

    # sys.exit(1)

    success = True
    for (i, f) in enumerate(line):
        validator = validators.get(field_types[i])
        if not validator or not validator(f):
            sys.stderr.write(f'failed validation for field {headers[i]} ({i}) with {field_types[i]} and value {f}\n')
            success = False
    if success:
        writer.writerow(line)

line_count = 0
headers = None
writer = csv.writer(sys.stdout)
reader = csv.reader(sys.stdin)
for line in reader:
    if line_count == 0:
        headers = line
        writer.writerow(headers)
    else:
        process_line(writer, headers, line)
    line_count += 1