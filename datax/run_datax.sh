#!/bin/bash

DATAX_HOME=/opt/datax
BASE_DIR=/mnt/d/s/作业/datax
DT=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "-1 day" +%Y-%m-%d)

echo "=== Running DataX tasks ==="
echo "Date: $DT"
echo "Yesterday: $YESTERDAY"
echo ""

run_task() {
    task_name=$1
    json_file=$2
    echo "Running task: $task_name"
    
    python3 $DATAX_HOME/bin/datax.py \
        -p "-Ddt=$DT -Dstart_time=$YESTERDAY 00:00:00 -Dend_time=$DT 00:00:00" \
        $BASE_DIR/$json_file
    
    if [ $? -eq 0 ]; then
        echo "✓ $task_name completed successfully"
    else
        echo "✗ $task_name failed"
        exit 1
    fi
    echo ""
}

run_task "ods_user_info" "ods_user_info.json"
run_task "ods_order_info" "ods_order_info.json"
run_task "ods_order_detail" "ods_order_detail.json"

echo "=== All DataX tasks completed ==="