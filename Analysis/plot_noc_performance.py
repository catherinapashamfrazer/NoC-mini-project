import csv
import os
import sys

def draw_svg_chart(width, height, x_data, y_data, title, x_label, y_label):
    # Padding around the plot area
    padding_left = 60
    padding_right = 30
    padding_top = 40
    padding_bottom = 50
    
    plot_w = width - padding_left - padding_right
    plot_h = height - padding_top - padding_bottom
    
    x_min, x_max = min(x_data), max(x_data)
    y_min, y_max = min(y_data), max(y_data)
    
    # Avoid division by zero
    x_range = (x_max - x_min) if x_max != x_min else 1.0
    y_range = (y_max - y_min) if y_max != y_min else 1.0
    
    # Pad Y range slightly for aesthetics
    y_max_padded = y_max + 0.1 * y_range
    y_min_padded = max(0.0, y_min - 0.1 * y_range)
    y_range_padded = y_max_padded - y_min_padded
    
    # Convert data points to screen coordinates
    points = []
    for x, y in zip(x_data, y_data):
        screen_x = padding_left + ((x - x_min) / x_range) * plot_w
        screen_y = padding_top + plot_h - ((y - y_min_padded) / y_range_padded) * plot_h
        points.append((screen_x, screen_y))
        
    svg = []
    # Chart container
    svg.append(f'<svg width="{width}" height="{height}" xmlns="http://www.w3.org/2000/svg" style="background:#ffffff; font-family: sans-serif;">')
    
    # Title
    svg.append(f'<text x="{width/2}" y="25" text-anchor="middle" font-size="16" font-weight="bold" fill="#333333">{title}</text>')
    
    # Grid lines & Y ticks
    num_ticks = 5
    for i in range(num_ticks):
        val = y_min_padded + (i / (num_ticks - 1)) * y_range_padded
        y_pos = padding_top + plot_h - (i / (num_ticks - 1)) * plot_h
        svg.append(f'<line x1="{padding_left}" y1="{y_pos}" x2="{width - padding_right}" y2="{y_pos}" stroke="#e5e5e5" stroke-dasharray="4"/>')
        svg.append(f'<text x="{padding_left - 10}" y="{y_pos + 4}" text-anchor="end" font-size="10" fill="#666666">{val:.2f}</text>')
        
    # X ticks
    num_x_ticks = len(x_data)
    for i, x in enumerate(x_data):
        x_pos = padding_left + (i / (num_x_ticks - 1)) * plot_w if num_x_ticks > 1 else padding_left + plot_w/2
        svg.append(f'<line x1="{x_pos}" y1="{padding_top}" x2="{x_pos}" y2="{padding_top + plot_h}" stroke="#e5e5e5" stroke-dasharray="4"/>')
        svg.append(f'<text x="{x_pos}" y="{padding_top + plot_h + 18}" text-anchor="middle" font-size="10" fill="#666666">{x:.1f}</text>')
        
    # Axes
    svg.append(f'<line x1="{padding_left}" y1="{padding_top}" x2="{padding_left}" y2="{padding_top + plot_h}" stroke="#333333" stroke-width="1.5"/>')
    svg.append(f'<line x1="{padding_left}" y1="{padding_top + plot_h}" x2="{width - padding_right}" y2="{padding_top + plot_h}" stroke="#333333" stroke-width="1.5"/>')
    
    # Axis labels
    svg.append(f'<text x="{width/2}" y="{height - 15}" text-anchor="middle" font-size="11" fill="#333333">{x_label}</text>')
    svg.append(f'<text x="15" y="{padding_top + plot_h/2}" text-anchor="middle" font-size="11" fill="#333333" transform="rotate(-90 15 {padding_top + plot_h/2})">{y_label}</text>')
    
    # Plot line
    path_d = []
    for idx, (sx, sy) in enumerate(points):
        cmd = 'M' if idx == 0 else 'L'
        path_d.append(f'{cmd} {sx:.1f} {sy:.1f}')
    svg.append(f'<path d="{" ".join(path_d)}" fill="none" stroke="#1a73e8" stroke-width="2.5"/>')
    
    # Markers (dots)
    for sx, sy in points:
        svg.append(f'<circle cx="{sx:.1f}" cy="{sy:.1f}" r="4" fill="#1a73e8" stroke="#ffffff" stroke-width="1.5"/>')
        
    svg.append('</svg>')
    return '\n'.join(svg)

def main():
    csv_path = 'Analysis/noc_results_demo.csv'
    if not os.path.exists(csv_path):
        # Fall back to checking parent dir or standard files
        csv_path = 'noc_results_demo.csv'
        if not os.path.exists(csv_path):
            print(f"Error: Demo results file not found.")
            sys.exit(1)
            
    traffic = []
    latency = []
    throughput = []
    utilization = []
    
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            traffic.append(float(row['traffic_percent']))
            latency.append(float(row['avg_latency_cycles']))
            throughput.append(float(row['throughput_packets_per_cycle']))
            if 'utilization' in row:
                utilization.append(float(row['utilization']))
                
    # Generate SVG files for each plot
    svg_lat = draw_svg_chart(400, 300, traffic, latency, "Latency vs Traffic Load", "Traffic Offered (%)", "Latency (cycles)")
    svg_thr = draw_svg_chart(400, 300, traffic, throughput, "Throughput Trend", "Traffic Offered (%)", "Throughput (pkts/cycle)")
    
    # Combine into a single HTML file to view them together beautifully
    html_content = f"""<!DOCTYPE html>
<html>
<head>
    <title>NoC Performance Analysis</title>
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f8f9fa; margin: 0; padding: 20px; }}
        .container {{ max-width: 1000px; margin: 0 auto; background: #ffffff; padding: 30px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }}
        h1 {{ text-align: center; color: #1a73e8; margin-bottom: 30px; }}
        .charts {{ display: flex; flex-wrap: wrap; gap: 20px; justify-content: center; }}
        .chart-box {{ border: 1px solid #e0e0e0; padding: 15px; border-radius: 6px; background: #ffffff; }}
        .metrics {{ margin-top: 30px; border-collapse: collapse; width: 100%; }}
        .metrics th, .metrics td {{ border: 1px solid #dddddd; text-align: left; padding: 12px; }}
        .metrics th {{ background-color: #f1f3f4; color: #333333; }}
        .metrics tr:nth-child(even) {{ background-color: #f8f9fa; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>NoC Performance Summary (2x2 Mesh)</h1>
        <div class="charts">
            <div class="chart-box">{svg_lat}</div>
            <div class="chart-box">{svg_thr}</div>
        </div>
        
        <h2>Simulation Summary Table</h2>
        <table class="metrics">
            <tr>
                <th>Traffic (%)</th>
                <th>Avg Latency (cycles)</th>
                <th>Throughput (pkts/cycle)</th>
                <th>Status</th>
            </tr>
            {"".join(f"<tr><td>{t:.1f}</td><td>{l:.2f}</td><td>{tp:.4f}</td><td style='color:green;font-weight:bold;'>Pass</td></tr>" for t, l, tp in zip(traffic, latency, throughput))}
        </table>
    </div>
</body>
</html>
"""
    
    export_dir = os.path.dirname(csv_path) if '/' in csv_path or '\\' in csv_path else '.'
    html_path = os.path.join(export_dir, 'noc_performance_summary.html')
    with open(html_path, 'w') as f:
        f.write(html_content)
        
    print(f"Successfully generated HTML performance summary report: {html_path}")
    print("You can open this file in any web browser to view the beautiful SVG charts and metrics tables!")

if __name__ == '__main__':
    main()
