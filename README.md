# Тренировочный стенд для изучения Iceberg

## Описание:

## Порты:

| Сервис | Порт | Примечание                                                                |
|--------|------|---------------------------------------------------------------------------|
|Nessie API|http://localhost:19120/|                                                                           |
|Trino UI|http://localhost:8082/| Вход по логину admin                                                      |
|Hue|http://localhost:8888/| Так-как при первом билде docker-compose то логин и пароль нужно придумать |
|Airflow|http://localhost:8081/| Логин и пароль admin                                                      |
|Jupyter|http://localhost:8889/||
|Spark Master|http://localhost:8080/||
|HDFS NameNode|http://localhost:9870/||
|YARN RM|http://localhost:8088/||

## Запуск:

Для запуска понадобится сделать следующее:
1. Склонировать репозиторий 
````bash 
git clone https://github.com/AlexZ0494/iceberg-migrate.git
````
2. Перейти в склонированную директорию и выполнить:
````bash
docker compose up -d --build
````
3. После развертывания проекта подождать от 1 до 3 минут чтобы все сервисы поднялись и выполнить следующее:
````bash
docker exec namenode hdfs dfs -mkdir -p /user/hive/warehouse
docker exec namenode hdfs dfs -mkdir -p /warehouse
docker exec namenode hdfs dfs -mkdir -p /spark-events
docker exec namenode hdfs dfs -chmod -R 777 /user/hive /warehouse /spark-events
````

Или использовать уже собранный shell-скрипт для развертывания проекта
Для Windows:
````bash
powershell -ExecutionPolicy Bypass -File .\start.ps1
````
Для Linux:
````bash
chmod +x start.sh
./start.sh
````

