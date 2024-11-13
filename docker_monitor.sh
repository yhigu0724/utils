#!/bin/bash

# 引数のバリデーション
if [ $# -ne 2 ]; then
    echo "Usage: $0 <container_name> <monitoring_hours>"
    echo "Example: $0 my_container 1"
    exit 1
fi

CONTAINER_NAME=$1
MONITORING_HOURS=$2
LOG_FILE="docker_stats_${CONTAINER_NAME}_$(date +%Y%m%d_%H%M%S).log"

# コンテナの存在確認
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: Container ${CONTAINER_NAME} is not running"
    exit 1
fi

# 監視時間を分に変換
TOTAL_MINUTES=$((MONITORING_HOURS * 60))
# 10分間の平均を計算するためのカウンター
COUNTER=0
# 一時データを保存する配列
declare -a CPU_DATA
declare -a MEM_DATA

echo "Starting monitoring of container ${CONTAINER_NAME} for ${MONITORING_HOURS} hour(s)"
echo "Logging to ${LOG_FILE}"
echo "Timestamp,CPU %,Memory %" >> "${LOG_FILE}"

calculate_average() {
    local sum=0
    local array=("$@")
    local len=${#array[@]}
    
    for value in "${array[@]}"; do
        sum=$(echo "$sum + $value" | bc -l)
    done
    
    echo "scale=2; $sum / $len" | bc -l
}

# メイン監視ループ
for ((minute=1; minute<=TOTAL_MINUTES; minute++)); do
    # CPU使用率を取得 (%)
    CPU_USAGE=$(docker stats --no-stream --format "{{.CPUPerc}}" "${CONTAINER_NAME}" | sed 's/%//')
    
    # メモリ使用率を取得 (%)
    MEM_USAGE=$(docker stats --no-stream --format "{{.MemPerc}}" "${CONTAINER_NAME}" | sed 's/%//')
    
    # 配列にデータを追加
    CPU_DATA[$COUNTER]=$CPU_USAGE
    MEM_DATA[$COUNTER]=$MEM_USAGE
    
    # タイムスタンプ付きで記録
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${TIMESTAMP},${CPU_USAGE},${MEM_USAGE}" >> "${LOG_FILE}"
    
    # カウンターをインクリメント
    COUNTER=$((COUNTER + 1))
    
    # 10分経過したら平均を計算
    if [ $COUNTER -eq 10 ]; then
        CPU_AVG=$(calculate_average "${CPU_DATA[@]}")
        MEM_AVG=$(calculate_average "${MEM_DATA[@]}")
        
        echo "=== ${TIMESTAMP} ===" >> "${LOG_FILE}"
        echo "Last 10 minutes averages:" >> "${LOG_FILE}"
        echo "CPU: ${CPU_AVG}%" >> "${LOG_FILE}"
        echo "Memory: ${MEM_AVG}%" >> "${LOG_FILE}"
        echo "====================" >> "${LOG_FILE}"
        
        # カウンターとデータをリセット
        COUNTER=0
        CPU_DATA=()
        MEM_DATA=()
    fi
    
    # 1分待機
    sleep 60
done

echo "Monitoring completed. Results saved in ${LOG_FILE}"