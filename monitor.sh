#!/bin/bash

# 使用法: ./monitor.sh <プロセスID> <監視時間(時間単位)>
PID=$1
DURATION=$2
INTERVAL=1800  # 30分間隔（秒単位）

if [ -z "$PID" ] || [ -z "$DURATION" ]; then
    echo "使用法: $0 <プロセスID> <監視時間(時間単位)>"
    exit 1
fi

# プロセスが存在するか確認
if ! ps -p $PID > /dev/null; then
    echo "指定されたPID ${PID} のプロセスが見つかりません"
    exit 1
fi

# 出力ファイル名を設定
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="process_stats_${PID}_${TIMESTAMP}.csv"

# ヘッダーを書き込む
echo "Timestamp,CPU_Usage(%),Memory_Usage(%),VSZ(KB),RSS(KB)" > $OUTPUT_FILE

# 監視回数を計算（30分間隔）
ITERATIONS=$(( $DURATION * 2 ))

for ((i=1; i<=$ITERATIONS; i++)); do
    # 現在のタイムスタンプ
    CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")
    
    # pidstatを使用してCPU使用率を取得（1秒間の平均）
    CPU_USAGE=$(pidstat -p $PID 1 1 | tail -n 1 | awk '{print $8}')
    
    # プロセスのメモリ情報を取得
    MEM_INFO=$(ps -p $PID -o %mem,vsz,rss --no-headers)
    MEM_PERCENT=$(echo $MEM_INFO | awk '{print $1}')
    VSZ=$(echo $MEM_INFO | awk '{print $2}')
    RSS=$(echo $MEM_INFO | awk '{print $3}')
    
    # データを記録
    echo "${CURRENT_TIME},${CPU_USAGE},${MEM_PERCENT},${VSZ},${RSS}" >> $OUTPUT_FILE
    
    # 30分待機
    sleep $INTERVAL
done

# 集計を表示
echo "=== 統計サマリー ==="
echo "監視期間: $(head -n 2 $OUTPUT_FILE | tail -n 1 | cut -d',' -f1) から $(tail -n 1 $OUTPUT_FILE | cut -d',' -f1)"
echo "平均CPU使用率: $(awk -F',' 'NR>1 {sum+=$2} END {print sum/(NR-1)}' $OUTPUT_FILE)%"
echo "平均メモリ使用率: $(awk -F',' 'NR>1 {sum+=$3} END {print sum/(NR-1)}' $OUTPUT_FILE)%"
echo "詳細な記録は ${OUTPUT_FILE} に保存されました"