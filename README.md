# Тренировочный стенд для изучения Iceberg

## Описание:

## Порты:

| Сервис | Порт | Примечание                                                                |
|--------|------|---------------------------------------------------------------------------|
|Nessie API|http://localhost:19120/|                                                                           |
|Trino UI|http://localhost:8082/| Вход по логину admin                                                      |
|Hue|http://localhost:8888/| Так-как при первом билде docker-compose то логин и пароль нужно придумать |
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
2. Перейти в склонированную директорию и запустить атоматический сборщик docker-compose:
Для Windows:
````bash
powershell -ExecutionPolicy Bypass -File .\start.ps1
````
По параметрам запуска:
1. .\start.ps1          # запустить кластер
2. .\start.ps1 stop     # остановить
3. .\start.ps1 restart  # перезапустить
4. .\start.ps1 logs     # логи
5. .\start.ps1 status   # статус
6. .\start.ps1 clean    # удалить всё
Для Linux:
````bash
chmod +x start.sh
./start.sh
````
По параметрам запуска:
1. ./start.sh          # запустить кластер
2. ./start.sh stop     # остановить
3. ./start.sh restart  # перезапустить
4. ./start.sh logs     # логи (опционально: ./start.sh logs trino)
5. ./start.sh status   # статус всех сервисов
6. ./start.sh clean    # удалить всё
7. ./start.sh help     # справка
