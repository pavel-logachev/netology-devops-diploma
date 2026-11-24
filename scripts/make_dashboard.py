"""Генерирует ansible/files/web-dashboard.json: USE-метрики веб-серверов и HTTP."""
import json
from pathlib import Path

panels, pid, y = [], 1, 0
DS = {"type": "prometheus", "uid": "prometheus"}


def row(title):
    global pid, y
    panels.append({"type": "row", "title": title, "id": pid, "collapsed": False,
                   "gridPos": {"h": 1, "w": 24, "x": 0, "y": y}})
    pid += 1
    y += 1


def ts(title, targets, unit, steps, x, w=8, maxv=None):
    global pid
    p = {
        "type": "timeseries", "title": title, "id": pid, "datasource": DS,
        "gridPos": {"h": 8, "w": w, "x": x, "y": y},
        "targets": [{"refId": chr(65 + i), "expr": e, "legendFormat": l, "datasource": DS}
                    for i, (e, l) in enumerate(targets)],
        "fieldConfig": {"defaults": {
            "unit": unit, "min": 0,
            "custom": {"thresholdsStyle": {"mode": "line+area"}, "fillOpacity": 10},
            "thresholds": {"mode": "absolute", "steps": [
                {"color": "green", "value": None},
                {"color": "orange", "value": steps[0]},
                {"color": "red", "value": steps[1]}]},
        }, "overrides": []},
        "options": {"legend": {"displayMode": "list", "placement": "bottom"},
                    "tooltip": {"mode": "multi"}},
    }
    if maxv is not None:
        p["fieldConfig"]["defaults"]["max"] = maxv
    panels.append(p)
    pid += 1


R = "[2m]"
row("Utilization")
ts("CPU: загрузка",
   [(f'100 * (1 - avg by(host)(rate(node_cpu_seconds_total{{mode="idle"}}{R})))', "{{host}}")],
   "percent", (70, 90), 0, 6, 100)
ts("RAM: занято",
   [('100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)', "{{host}}")],
   "percent", (80, 90), 6, 6, 100)
ts("Диск: занято место на /",
   [('100 * (1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})', "{{host}}")],
   "percent", (80, 90), 12, 6, 100)
ts("Сеть: трафик eth0",
   [(f'rate(node_network_receive_bytes_total{{device="eth0"}}{R})', "{{host}} rx"),
    (f'rate(node_network_transmit_bytes_total{{device="eth0"}}{R})', "{{host}} tx")],
   "Bps", (10e6, 50e6), 18, 6)
y += 8
row("Saturation")
ts("CPU: load average 1m на ядро",
   [('node_load1 / on(host) count by(host)(node_cpu_seconds_total{mode="idle"})', "{{host}}")],
   "short", (1, 2), 0, 6)
ts("CPU: steal (ВМ с 20% vCPU)",
   [(f'100 * avg by(host)(rate(node_cpu_seconds_total{{mode="steal"}}{R}))', "{{host}}")],
   "percent", (20, 50), 6, 6, 100)
ts("RAM: major page faults",
   [(f'rate(node_vmstat_pgmajfault{R})', "{{host}}")],
   "ops", (50, 200), 12, 6)
ts("Диск: средняя очередь I/O",
   [(f'rate(node_disk_io_time_weighted_seconds_total{{device=~"vd.*"}}{R})', "{{host}} {{device}}")],
   "short", (1, 2), 18, 6)
y += 8
row("Errors")
ts("Сеть: ошибки и отброшенные пакеты",
   [(f'rate(node_network_receive_errs_total{{device="eth0"}}{R}) + rate(node_network_transmit_errs_total{{device="eth0"}}{R})', "{{host}} errs"),
    (f'rate(node_network_receive_drop_total{{device="eth0"}}{R}) + rate(node_network_transmit_drop_total{{device="eth0"}}{R})', "{{host}} drop")],
   "pps", (1, 10), 0, 8)
ts("Диск: ошибки ФС и read-only",
   [('node_filesystem_device_error{mountpoint="/"} + node_filesystem_readonly{mountpoint="/"}', "{{host}}")],
   "short", (0.5, 1), 8, 8)
ts("HTTP: ответы 4xx и 5xx",
   [(f'sum by(host)(rate(nginx_http_response_count_total{{status=~"5.."}}{R}))', "{{host}} 5xx"),
    (f'sum by(host)(rate(nginx_http_response_count_total{{status=~"4.."}}{R}))', "{{host}} 4xx")],
   "reqps", (0.1, 1), 16, 8)
y += 8
row("HTTP (nginx log exporter)")
ts("http_response_count_total: запросы в секунду",
   [(f'sum by(host, status)(rate(nginx_http_response_count_total{R}))', "{{host}} {{status}}")],
   "reqps", (50, 100), 0, 12)
ts("http_response_size_bytes: объем ответов",
   [(f'sum by(host)(rate(nginx_http_response_size_bytes{R}))', "{{host}}")],
   "Bps", (1e6, 5e6), 12, 12)

dash = {"uid": "diploma-web", "title": "Веб-серверы: USE и HTTP", "tags": ["diploma"],
        "timezone": "browser", "schemaVersion": 39, "version": 1, "refresh": "30s",
        "time": {"from": "now-1h", "to": "now"}, "panels": panels}
out = Path(__file__).resolve().parent.parent / "ansible" / "files" / "web-dashboard.json"
out.write_text(json.dumps(dash, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(out, len(panels))
