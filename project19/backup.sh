TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="/tmp/backup_${TIMESTAMP}.log"

echo "Capstone scheduled backup created at ${TIMESTAMP}" > "$LOG_FILE"
aws s3 cp "$LOG_FILE" s3://capstone-static-site-8ca2c17c/backups/ --region eu-north-1
