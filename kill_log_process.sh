stop() {
    if [ -f "$pid_file" ]; then
        pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            kill "$pid"
            # プロセスが確実に終了するまで少し待つ
            for i in {1..5}; do
                if ! ps -p "$pid" > /dev/null 2>&1; then
                    break
                fi
                sleep 1
            done
            # それでも終了していない場合は強制終了
            if ps -p "$pid" > /dev/null 2>&1; then
                kill -9 "$pid"
                sleep 1
            fi
        fi
        rm -f "$pid_file"
        return 0
    else
        echo "PID file not found: $pid_file"
        return 0  # PIDファイルが存在しない場合でもエラーとしない
    fi
}