#!/bin/bash

# 基本設定
LOG_DIR="/var/log/containerapp"
PID_DIR="/var/run/containerapp"
PREFIX="cc_"

# 必要なディレクトリの作成
mkdir -p $LOG_DIR $PID_DIR

usage() {
    echo "Usage: $0 [start|stop] <container_number>"
    echo "Example:"
    echo "  $0 start 01  # Start container cc_01"
    echo "  $0 stop 02   # Stop container cc_02"
    exit 1
}

# 引数チェック
if [ $# -ne 2 ]; then
    usage
fi

# コンテナ番号のバリデーション
if ! [[ $2 =~ ^[0-9]{2}$ ]]; then
    echo "Error: Container number must be two digits (01-99)"
    exit 1
fi

# 変数設定
action=$1
container_num=$2
container_name="${PREFIX}${container_num}"
log_file="${LOG_DIR}/${container_name}.log"
pid_file="${PID_DIR}/${container_name}.pid"

start_container() {
    # コンテナ存在チェック
    if docker ps -a | grep -q $container_name; then
        echo "Error: Container $container_name already exists"
        exit 1
    fi

    # PIFファイルチェック
    if [ -f $pid_file ]; then
        echo "Error: Logging process already running"
        exit 1
    fi

    echo "Starting container $container_name..."
    
    # コンテナ起動
    docker run -d --name $container_name image01
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to start container"
        exit 1
    fi

    # ログ収集開始
    docker logs -f $container_name > $log_file 2>&1 &
    echo $! > $pid_file
    
    echo "Container $container_name started and logging initialized"
}

stop_container() {
    # ログプロセス停止
    if [ -f $pid_file ]; then
        echo "Stopping logging process for $container_name..."
        kill $(cat $pid_file)
        rm $pid_file
    fi

    # コンテナ停止と削除
    if docker ps -a | grep -q $container_name; then
        echo "Stopping container $container_name..."
        docker stop $container_name
        docker rm $container_name
        echo "Container $container_name stopped and removed"
    else
        echo "Warning: Container $container_name not found"
    fi

    # 古いログファイルの圧縮（オプション）
    if [ -f $log_file ]; then
        gzip -9 $log_file
        mv $log_file.gz ${log_file}.$(date +%Y%m%d).gz
    fi
}

case "$action" in
    start)
        start_container
        ;;
    stop)
        stop_container
        ;;
    *)
        usage
        ;;
esac

exit 0