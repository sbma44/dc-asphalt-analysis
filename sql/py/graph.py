import csv
import plotly.graph_objects as go
from plotly.io import write_image

def create_horizontal_bar_chart_and_save_png(data, file_name='chart.png', individual_colors=None):
    # Extract labels and values
    labels = [item[0] for item in data]
    values = [item[1] for item in data]

    # Create the bar chart
    fig = go.Figure(go.Bar(
        x=values,
        y=labels,
        orientation='h',
        marker=dict(color=individual_colors),  # Set bar colors
        text=values,
        textposition='auto',
    ))

    # Customize layout
    fig.update_layout(
        title='DC/MD/VA Asphalt Plants by Census Tract Population Density',
        plot_bgcolor='white',
        xaxis=dict(title='population/km^2', tickcolor='lightgray'),
        yaxis=dict(tickcolor='lightgray', autorange="reversed"),
        bargap=0.2,
        height=len(data) * 25,
        margin=dict(l=100, r=50, t=50, b=50)
    )

    # Save the figure as a PNG
    fig.write_image(file_name, width=660)

with open('plant_pop_density.csv') as f:
    reader = csv.DictReader(f)
    data = [(row['name'] + ' ', round(float(row['pop density'])), row['state']) for row in reader if len(row['name'].strip()) > 0]
    data.sort(key=lambda x: x[1], reverse=True)

    individual_colors = ['#e5f5f9'] * len(data)  # Specify individual colors for each bar

    for (i, d) in enumerate(data):
        if d[2] == 'DC':
            individual_colors[i] = 'red'
        elif d[2] == 'MD':
            individual_colors[i] = '#99d8c9'
        print(d)

create_horizontal_bar_chart_and_save_png(data, 'horizontal_bar_chart.png', individual_colors)
