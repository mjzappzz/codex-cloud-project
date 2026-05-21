#!/usr/bin/env bash

set -Eeuo pipefail

usage() {
    cat <<'EOF'
Usage:
  ./cpu_mem_stress_report.sh [DURATION_SECONDS] [INTERVAL_SECONDS]
  ./cpu_mem_stress_report.sh --install-deps

Environment overrides:
  CPU_WORKERS      CPU worker count, default: nproc
  VM_WORKERS       VM worker count, default: max(1, CPU_WORKERS / 8)
  VM_BYTES         VM memory target, default: 85%
  SWAP_FAIL_MB     Swap usage failure threshold, default: 1024
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

install_deps() {
    echo "[INFO] Checking and installing dependencies..."

    if [[ "$(id -u)" -ne 0 ]]; then
        echo "[ERROR] 请使用 root 用户运行，或使用 sudo"
        exit 1
    fi

    if [[ -f /etc/redhat-release ]]; then
        echo "[INFO] Detected RHEL/CentOS/Rocky/Alma"
        local pkg_cmd="yum"
        command -v dnf >/dev/null 2>&1 && pkg_cmd="dnf"
        "$pkg_cmd" install -y epel-release
        "$pkg_cmd" install -y stress-ng python3 python3-pip python3-openpyxl
    elif [[ -f /etc/debian_version ]]; then
        echo "[INFO] Detected Debian/Ubuntu"
        apt-get update
        apt-get install -y stress-ng python3 python3-pip python3-openpyxl
    else
        echo "[ERROR] Unsupported OS"
        exit 1
    fi

    python3 - <<'PYCHK'
try:
    import openpyxl
except Exception:
    import subprocess
    subprocess.check_call(["python3", "-m", "pip", "install", "openpyxl"])
PYCHK

    echo "[INFO] Dependency check done."
}

if [[ "${1:-}" == "--install-deps" ]]; then
    install_deps
    exit 0
fi

if [[ "$(id -u)" -ne 0 ]]; then
    echo "[ERROR] 本脚本需要 root 权限，以便读取 dmesg 并执行稳定性压测"
    exit 1
fi

DURATION="${1:-43200}"
INTERVAL="${2:-2}"
TIME_TAG="$(date +%F_%H%M%S)"
WORKDIR="$(pwd)"

STRESS_LOG="${WORKDIR}/stress_cpu_mem_${TIME_TAG}.log"
MON_LOG="${WORKDIR}/cpu_mem_monitor_${TIME_TAG}.csv"
ERR_LOG="${WORKDIR}/cpu_mem_error_${TIME_TAG}.log"
REPORT="${WORKDIR}/cpu_mem_report_${TIME_TAG}.txt"
XLSX_REPORT="${WORKDIR}/cpu_mem_report_${TIME_TAG}.xlsx"

CPU_WORKERS="${CPU_WORKERS:-$(nproc)}"
CPU_CORES="$(nproc)"
VM_WORKERS="${VM_WORKERS:-$(( CPU_WORKERS / 8 ))}"
(( VM_WORKERS < 1 )) && VM_WORKERS=1

VM_BYTES="${VM_BYTES:-85%}"
SWAP_FAIL_MB="${SWAP_FAIL_MB:-1024}"
RUN_INSTALL_HINT="${RUN_INSTALL_HINT:-./cpu_mem_stress_report.sh --install-deps}"

CRITICAL_ERR_PATTERN="out of memory|oom-killer|killed process|hardware error|machine check error|machine check exception|mce:.*error|edac.*error|ecc.*uncorrected|uncorrected error|thermal thrott|throttling|segfault|general protection fault|verification failed"

MON_PID=""
ERR_PID=""
START_TS=""
END_TS=""
TEST_SECONDS="0"
SAMPLE_COUNT="0"

cleanup() {
    set +e
    [[ -n "${MON_PID}" ]] && kill "${MON_PID}" >/dev/null 2>&1
    [[ -n "${ERR_PID}" ]] && kill "${ERR_PID}" >/dev/null 2>&1
    wait "${MON_PID}" >/dev/null 2>&1 || true
    wait "${ERR_PID}" >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

command -v stress-ng >/dev/null 2>&1 || {
    echo "ERROR: stress-ng not found. 请先执行: ${RUN_INSTALL_HINT}"
    exit 1
}

command -v python3 >/dev/null 2>&1 || {
    echo "ERROR: python3 not found. 请先执行: ${RUN_INSTALL_HINT}"
    exit 1
}

python3 - <<'PYCHK'
try:
    import openpyxl
except Exception:
    raise SystemExit("ERROR: python3-openpyxl not found. Install with --install-deps or pip install openpyxl")
PYCHK

CPU_MODEL="$(lscpu | awk -F: '/Model name/ {gsub(/^ +/,"",$2); print $2; exit}')"
MEM_TOTAL="$(free -h | awk '/Mem:/ {print $2}')"
OS_INFO="$(awk -F= '/^PRETTY_NAME=/ {gsub(/"/,"",$2); print $2}' /etc/os-release 2>/dev/null || true)"
[[ -z "${OS_INFO}" ]] && OS_INFO="Unknown Linux"

echo "======================================"
echo "CPU + Memory Stress Test Start"
echo "CPU Workers : ${CPU_WORKERS}"
echo "VM Workers  : ${VM_WORKERS}"
echo "VM Bytes    : ${VM_BYTES}"
echo "Duration    : ${DURATION}s"
echo "Interval    : ${INTERVAL}s"
echo "Workdir     : ${WORKDIR}"
echo "======================================"

START_TS="$(date '+%F %T')"

(
    echo "timestamp,load1,load5,load15,mem_total_MB,mem_used_MB,mem_free_MB,mem_available_MB,swap_total_MB,swap_used_MB"
    while true; do
        TS="$(date '+%F %T')"
        read -r LOAD1 LOAD5 LOAD15 _ < /proc/loadavg
        MEM_LINE="$(free -m | awk '/Mem:/ {print $2","$3","$4","$7}')"
        SWAP_LINE="$(free -m | awk '/Swap:/ {print $2","$3}')"
        echo "${TS},${LOAD1},${LOAD5},${LOAD15},${MEM_LINE},${SWAP_LINE}"
        sleep "${INTERVAL}"
    done
) > "${MON_LOG}" &
MON_PID=$!

(
    dmesg -w 2>/dev/null | grep --line-buffered -Ei "${CRITICAL_ERR_PATTERN}" > "${ERR_LOG}"
) &
ERR_PID=$!

sleep 2

set +e
stress-ng \
    --cpu "${CPU_WORKERS}" \
    --cpu-method all \
    --vm "${VM_WORKERS}" \
    --vm-bytes "${VM_BYTES}" \
    --vm-method all \
    --vm-keep \
    --verify \
    --timeout "${DURATION}s" \
    --metrics-brief \
    2>&1 | tee "${STRESS_LOG}"
STRESS_EXIT=${PIPESTATUS[0]}
set -e

END_TS="$(date '+%F %T')"

cleanup

TEST_SECONDS="$(
    python3 - <<PYEOF
from datetime import datetime
start = datetime.strptime("${START_TS}", "%Y-%m-%d %H:%M:%S")
end = datetime.strptime("${END_TS}", "%Y-%m-%d %H:%M:%S")
print(int((end - start).total_seconds()))
PYEOF
)"

SAMPLE_COUNT="$(awk 'END {print NR > 1 ? NR - 1 : 0}' "${MON_LOG}")"
LOAD1_AVG="$(awk -F',' 'NR>1 {sum+=$2; n++} END{if(n>0) printf "%.2f", sum/n; else print "0.00"}' "${MON_LOG}")"
LOAD1_MAX="$(awk -F',' 'NR>1 {if($2>max) max=$2} END{printf "%.2f", max+0}' "${MON_LOG}")"
LOAD5_AVG="$(awk -F',' 'NR>1 {sum+=$3; n++} END{if(n>0) printf "%.2f", sum/n; else print "0.00"}' "${MON_LOG}")"
LOAD15_AVG="$(awk -F',' 'NR>1 {sum+=$4; n++} END{if(n>0) printf "%.2f", sum/n; else print "0.00"}' "${MON_LOG}")"

MEM_USED_AVG="$(awk -F',' 'NR>1 {sum+=$6; n++} END{if(n>0) printf "%.2f", sum/n; else print "0.00"}' "${MON_LOG}")"
MEM_USED_MAX="$(awk -F',' 'NR>1 {if($6>max) max=$6} END{printf "%.0f", max+0}' "${MON_LOG}")"
MEM_AVAIL_MIN="$(awk -F',' 'NR>1 {if(NR==2 || $8<min) min=$8} END{printf "%.0f", min+0}' "${MON_LOG}")"
SWAP_USED_MAX="$(awk -F',' 'NR>1 {if($10>max) max=$10} END{printf "%.0f", max+0}' "${MON_LOG}")"

ERROR_COUNT="$(grep -Eic "${CRITICAL_ERR_PATTERN}" "${ERR_LOG}" 2>/dev/null || true)"
STRESS_ERROR="$(grep -Ei 'verification failed|aborted|segmentation fault|bus error|out of memory|oom-killer|killed process|stress-ng: fail:' "${STRESS_LOG}" || true)"

RESULT="PASS"
REASON="No critical error detected."
FAIL_REASONS=()

if [[ "${STRESS_EXIT}" != "0" ]]; then
    FAIL_REASONS+=("stress-ng exited abnormally (exit code: ${STRESS_EXIT})")
fi

if (( SWAP_USED_MAX > SWAP_FAIL_MB )); then
    FAIL_REASONS+=("swap usage exceeded threshold (${SWAP_USED_MAX} MB > ${SWAP_FAIL_MB} MB)")
fi

if [[ "${ERROR_COUNT}" != "0" ]]; then
    FAIL_REASONS+=("critical kernel error detected (${ERROR_COUNT} entries)")
fi

if [[ -n "${STRESS_ERROR}" ]]; then
    FAIL_REASONS+=("stress-ng reported critical runtime errors")
fi

if (( ${#FAIL_REASONS[@]} > 0 )); then
    RESULT="FAIL"
    REASON="$(IFS='; '; echo "${FAIL_REASONS[*]}")"
fi

cat > "${REPORT}" <<EOR
CPU + 内存稳定性压力测试报告

一、测试概述
本次测试针对服务器 CPU 与内存进行持续高负载压力测试，验证设备在长时间满载条件下的计算稳定性、内存稳定性、系统可靠性及异常告警情况。

二、测试对象
操作系统              : ${OS_INFO}
CPU型号               : ${CPU_MODEL}
逻辑线程数            : ${CPU_CORES}
内存总量              : ${MEM_TOTAL}

三、测试方法
测试工具              : stress-ng
CPU压力线程           : ${CPU_WORKERS}
CPU测试方法           : all
内存压力线程          : ${VM_WORKERS}
内存占用比例          : ${VM_BYTES}
内存测试方法          : all
数据校验              : verify enabled
测试计划时长          : ${DURATION} 秒
实际执行时长          : ${TEST_SECONDS} 秒
采样间隔              : ${INTERVAL} 秒
采样点数量            : ${SAMPLE_COUNT}
Swap失败阈值          : ${SWAP_FAIL_MB} MB

四、测试结果汇总

1. CPU负载
平均1分钟负载          : ${LOAD1_AVG}
最高1分钟负载          : ${LOAD1_MAX}
平均5分钟负载          : ${LOAD5_AVG}
平均15分钟负载         : ${LOAD15_AVG}

2. 内存表现
平均已用内存          : ${MEM_USED_AVG} MB
最高已用内存          : ${MEM_USED_MAX} MB
最低可用内存          : ${MEM_AVAIL_MIN} MB
最大Swap使用          : ${SWAP_USED_MAX} MB

3. 异常检查
stress-ng退出码        : ${STRESS_EXIT}
重大内核异常数量      : ${ERROR_COUNT}
stress-ng严重错误      : $( [[ -z "${STRESS_ERROR}" ]] && echo "未发现" || echo "发现严重错误，请查看 ${STRESS_LOG}" )
OOM / MCE / ECC / Thermal Throttling : $( [[ "${ERROR_COUNT}" == "0" ]] && echo "未发现重大异常" || echo "发现重大异常，请查看 ${ERR_LOG}" )

五、通过判据
1. stress-ng 退出码必须为 0
2. stress-ng 不得出现 verification failed、segmentation fault、bus error、OOM 等关键错误
3. 内核日志不得出现 OOM、Machine Check Error、ECC uncorrected error、Hardware Error、Thermal Throttling 等重大异常
4. Swap 使用量允许少量波动，但超过 ${SWAP_FAIL_MB} MB 视为失败

六、综合判定
测试结果              : ${RESULT}
判定原因              : ${REASON}

七、结论
$(if [[ "${RESULT}" == "PASS" ]]; then
cat <<'PASS_TEXT'
本次 CPU + 内存压力测试期间，系统在高负载条件下持续运行，未发现 OOM、MCE、ECC、thermal throttling 等重大异常，stress-ng 未报告计算或内存校验错误。

综合判断：该服务器在本次测试条件下 CPU 与内存运行稳定，测试结果通过。
PASS_TEXT
else
cat <<'FAIL_TEXT'
本次 CPU + 内存压力测试未通过。测试期间检测到重大异常或资源风险。建议结合 stress-ng 日志、资源监控日志和内核错误日志进一步排查 CPU、内存、散热、供电或系统配置问题。
FAIL_TEXT
fi)

八、原始文件
stress-ng日志          : ${STRESS_LOG}
资源监控日志          : ${MON_LOG}
内核错误日志          : ${ERR_LOG}
Excel报告             : ${XLSX_REPORT}

九、报告生成信息
测试开始时间          : ${START_TS}
测试结束时间          : ${END_TS}
报告生成时间          : $(date '+%F %T')
EOR

echo
echo "======================================"
echo "Excel 报告生成中..."
echo "======================================"

python3 - <<PYEOF
import csv
from pathlib import Path
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Border, Side, Alignment
from openpyxl.chart import LineChart, Reference
from openpyxl.utils import get_column_letter

report = Path("${REPORT}")
stress_log = Path("${STRESS_LOG}")
mon_log = Path("${MON_LOG}")
err_log = Path("${ERR_LOG}")
xlsx = Path("${XLSX_REPORT}")

result = "${RESULT}"
reason = "${REASON}"

wb = Workbook()
ws = wb.active
ws.title = "Summary"
raw = wb.create_sheet("RawReport")
stress = wb.create_sheet("StressLog")
mon = wb.create_sheet("MonitorCSV")
err = wb.create_sheet("KernelError")

dark = "1F4E78"
green = "C6EFCE"
red = "FFC7CE"
gray = "F2F2F2"
white = "FFFFFF"

border = Border(
    left=Side(style="thin", color="D9D9D9"),
    right=Side(style="thin", color="D9D9D9"),
    top=Side(style="thin", color="D9D9D9"),
    bottom=Side(style="thin", color="D9D9D9"),
)

ws.merge_cells("A1:H1")
ws["A1"] = "CPU + 内存稳定性压力测试报告"
ws["A1"].font = Font(size=18, bold=True, color=white)
ws["A1"].fill = PatternFill("solid", fgColor=dark)
ws["A1"].alignment = Alignment(horizontal="center", vertical="center")
ws.row_dimensions[1].height = 30

def section(row, title):
    ws.merge_cells(start_row=row, start_column=1, end_row=row, end_column=8)
    c = ws.cell(row=row, column=1, value=title)
    c.font = Font(bold=True, color=white)
    c.fill = PatternFill("solid", fgColor=dark)
    return row + 1

def kv(row, key, value):
    ws.cell(row=row, column=1, value=key)
    ws.cell(row=row, column=2, value=value)
    for col in range(1, 3):
        cell = ws.cell(row=row, column=col)
        cell.border = border
        cell.alignment = Alignment(vertical="center", wrap_text=True)
    ws.cell(row=row, column=1).fill = PatternFill("solid", fgColor=gray)
    ws.cell(row=row, column=1).font = Font(bold=True)
    return row + 1

r = 3
r = section(r, "一、测试对象")
for k, v in [
    ("操作系统", "${OS_INFO}"),
    ("CPU型号", "${CPU_MODEL}"),
    ("逻辑线程数", "${CPU_CORES}"),
    ("内存总量", "${MEM_TOTAL}"),
]:
    r = kv(r, k, v)

r += 1
r = section(r, "二、测试方法")
for k, v in [
    ("测试工具", "stress-ng"),
    ("CPU压力线程", "${CPU_WORKERS}"),
    ("CPU测试方法", "all"),
    ("内存压力线程", "${VM_WORKERS}"),
    ("内存占用比例", "${VM_BYTES}"),
    ("内存测试方法", "all"),
    ("数据校验", "verify enabled"),
    ("测试计划时长", "${DURATION} 秒"),
    ("实际执行时长", "${TEST_SECONDS} 秒"),
    ("采样间隔", "${INTERVAL} 秒"),
    ("采样点数量", "${SAMPLE_COUNT}"),
    ("Swap失败阈值", "${SWAP_FAIL_MB} MB"),
]:
    r = kv(r, k, v)

r += 1
r = section(r, "三、测试结果汇总")

headers = ["类别", "指标", "数值"]
for i, h in enumerate(headers, 1):
    cell = ws.cell(row=r, column=i, value=h)
    cell.font = Font(bold=True, color=white)
    cell.fill = PatternFill("solid", fgColor=dark)
    cell.border = border
r += 1

rows = [
    ("CPU负载", "平均1分钟负载", "${LOAD1_AVG}"),
    ("CPU负载", "最高1分钟负载", "${LOAD1_MAX}"),
    ("CPU负载", "平均5分钟负载", "${LOAD5_AVG}"),
    ("CPU负载", "平均15分钟负载", "${LOAD15_AVG}"),
    ("内存表现", "平均已用内存", "${MEM_USED_AVG} MB"),
    ("内存表现", "最高已用内存", "${MEM_USED_MAX} MB"),
    ("内存表现", "最低可用内存", "${MEM_AVAIL_MIN} MB"),
    ("内存表现", "最大Swap使用", "${SWAP_USED_MAX} MB"),
    ("异常检查", "stress-ng退出码", "${STRESS_EXIT}"),
    ("异常检查", "重大内核异常数量", "${ERROR_COUNT}"),
    ("综合判定", "测试结果", "${RESULT}"),
]

for row in rows:
    for c, v in enumerate(row, 1):
        cell = ws.cell(row=r, column=c, value=v)
        cell.border = border
        cell.alignment = Alignment(vertical="center", wrap_text=True)
        if row[1] == "测试结果" and c == 3:
            cell.fill = PatternFill("solid", fgColor=green if result == "PASS" else red)
            cell.font = Font(bold=True)
    r += 1

r += 1
r = section(r, "四、判定说明")
r = kv(r, "判定原因", reason)
r = kv(r, "测试开始时间", "${START_TS}")
r = kv(r, "测试结束时间", "${END_TS}")
r = kv(r, "报告生成时间", "$(date '+%F %T')")

for col, width in {"A":18, "B":34, "C":24, "D":14, "E":14, "F":14, "G":14, "H":14}.items():
    ws.column_dimensions[col].width = width

if report.exists():
    for line in report.read_text(errors="ignore").splitlines():
        raw.append([line])
raw.column_dimensions["A"].width = 130

if stress_log.exists():
    for line in stress_log.read_text(errors="ignore").splitlines():
        stress.append([line])
stress.column_dimensions["A"].width = 130

if err_log.exists() and err_log.stat().st_size > 0:
    for line in err_log.read_text(errors="ignore").splitlines():
        err.append([line])
else:
    err.append(["No critical kernel error detected."])
err.column_dimensions["A"].width = 130

def to_number(v):
    try:
        return float(str(v).strip())
    except Exception:
        return v

if mon_log.exists():
    with mon_log.open(errors="ignore", newline="") as f:
        reader = csv.reader(f)
        for idx, row in enumerate(reader, 1):
            out = []
            for j, val in enumerate(row, 1):
                if idx > 1 and j >= 2:
                    out.append(to_number(val))
                else:
                    out.append(val.strip() if isinstance(val, str) else val)
            mon.append(out)

for sheet in [raw, stress, mon, err]:
    sheet.freeze_panes = "A2"
    if sheet.max_row >= 1:
        for cell in sheet[1]:
            cell.font = Font(bold=True, color=white)
            cell.fill = PatternFill("solid", fgColor=dark)

for col in range(1, mon.max_column + 1):
    mon.column_dimensions[get_column_letter(col)].width = 22

if mon.max_row > 2 and mon.max_column >= 10:
    def add_chart(title, col, pos):
        chart = LineChart()
        chart.title = title
        chart.y_axis.title = title
        chart.x_axis.title = "Sample"
        data = Reference(mon, min_col=col, min_row=1, max_row=mon.max_row)
        chart.add_data(data, titles_from_data=True)
        chart.height = 7
        chart.width = 14
        ws.add_chart(chart, pos)

    add_chart("Load 1min", 2, "J3")
    add_chart("Load 5min", 3, "J18")
    add_chart("Load 15min", 4, "J33")
    add_chart("Memory Used(MB)", 6, "J48")
    add_chart("Memory Available(MB)", 8, "J63")
    add_chart("Swap Used(MB)", 10, "J78")

for sheet in wb.worksheets:
    for row in sheet.iter_rows():
        for cell in row:
            cell.border = border
            cell.alignment = Alignment(wrap_text=True, vertical="center")

wb.save(xlsx)
print(f"XLSX Report : {xlsx}")
PYEOF

echo
echo "======================================"
echo "CPU + Memory Stress Test Finished"
echo "Result       : ${RESULT}"
echo "Reason       : ${REASON}"
echo "CPU Workers  : ${CPU_WORKERS}"
echo "VM Workers   : ${VM_WORKERS}"
echo "Stress Log   : ${STRESS_LOG}"
echo "Monitor CSV  : ${MON_LOG}"
echo "Kernel Error : ${ERR_LOG}"
echo "Text Report  : ${REPORT}"
echo "XLSX Report  : ${XLSX_REPORT}"
echo "======================================"
