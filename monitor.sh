#!/bin/bash

# 使用法: ./monitor_average.sh <プロセスID> <監視時間(時間単位)>
PID=$1
DURATION=$2
INTERVAL=1800  # 30分間隔（秒単位）
SAMPLE_INTERVAL=60  # サンプリング間隔（秒単位）

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

# 一時ファイル作成
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# ヘッダーを書き込む
echo "Timestamp,Avg_CPU_Usage(%),Avg_Memory_Usage(%),VSZ(KB),RSS(KB)" > $OUTPUT_FILE

# 監視回数を計算（30分間隔）
ITERATIONS=$(( $DURATION * 2 ))

for ((i=1; i<=$ITERATIONS; i++)); do
    START_TIME=$(date +%s)
    CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")
    
    # 30個のサンプルを収集（30分間で1分ごと）
    CPU_SAMPLES=0
    MEM_SAMPLES=0
    SAMPLES_COUNT=0
    
    # 一時ファイルをクリア
    > $TEMP_FILE
    
    # 30分間のサンプリング
    while [ $(( $(date +%s) - $START_TIME )) -lt $INTERVAL ]; do
        # CPU使用率を取得（1秒間の平均）
        CPU_USAGE=$(pidstat -p $PID 1 1 | tail -n 1 | awk '{print $8}')
        
        # メモリ情報を取得
        MEM_INFO=$(ps -p $PID -o %mem,vsz,rss --no-headers)
        MEM_PERCENT=$(echo $MEM_INFO | awk '{print $1}')
        VSZ=$(echo $MEM_INFO | awk '{print $2}')
        RSS=$(echo $MEM_INFO | awk '{print $3}')
        
        # サンプルを一時ファイルに保存
        echo "${CPU_USAGE},${MEM_PERCENT},${VSZ},${RSS}" >> $TEMP_FILE
        
        SAMPLES_COUNT=$((SAMPLES_COUNT + 1))
        
        # 次のサンプリングまで待機
        sleep $SAMPLE_INTERVAL
    done
    
    # 30分間の平均値を計算
    AVERAGES=$(awk -F',' '
        BEGIN {cpu_sum=0; mem_sum=0; vsz_sum=0; rss_sum=0; count=0}
        {
            cpu_sum+=$1
            mem_sum+=$2
            vsz_sum+=$3
            rss_sum+=$4
            count++
        }
        END {
            print cpu_sum/count","mem_sum/count","vsz_sum/count","rss_sum/count
        }' $TEMP_FILE)
    
    # 結果を出力ファイルに書き込む
    echo "${CURRENT_TIME},${AVERAGES}" >> $OUTPUT_FILE
    
    # 次の30分間の測定まで待機（必要な場合）
    ELAPSED=$(($(date +%s) - $START_TIME))
    if [ $ELAPSED -lt $INTERVAL ]; then
        sleep $(($INTERVAL - $ELAPSED))
    fi
done

# 集計を表示
echo "=== 統計サマリー ==="
echo "監視期間: $(head -n 2 $OUTPUT_FILE | tail -n 1 | cut -d',' -f1) から $(tail -n 1 $OUTPUT_FILE | cut -d',' -f1)"
echo "サンプリング間隔: ${SAMPLE_INTERVAL}秒"
echo "30分あたりのサンプル数: 平均 $SAMPLES_COUNT 個"
echo ""
echo "全期間の平均値:"
echo "- CPU使用率: $(awk -F',' 'NR>1 {sum+=$2} END {print sum/(NR-1)}' $OUTPUT_FILE)%"
echo "- メモリ使用率: $(awk -F',' 'NR>1 {sum+=$3} END {print sum/(NR-1)}' $OUTPUT_FILE)%"
echo "詳細な記録は ${OUTPUT_FILE} に保存されました"