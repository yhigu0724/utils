check_status() {
    if [ -f $pid_file ]; then
        echo "Logging process: Running (PID: $(cat $pid_file))"
    else
        echo "Logging process: Not running"
    fi

    if docker ps | grep -q $container_name; then
        echo "Container: Running"
    else
        echo "Container: Not running"
    fi
}

# caseステートメントに追加
case "$1" in
    start)
        start_container
        ;;
    stop)
        stop_container
        ;;
    status)
        check_status
        ;;
    *)
        usage
        ;;
esac