#!/bin/sh
source .env

mkdir -p \
    $AIRFLOW_PROJ_DIR/dags\
    $AIRFLOW_PROJ_DIR/logs\
    $AIRFLOW_PROJ_DIR/plugins\
    $AIRFLOW_PROJ_DIR/config

if [ -z $AIRFLOW_UID ]; then
  echo "AIRFLOW_UID=$(id -u)" >> .env
fi

docker compose up airflow-init
docker compose up -d