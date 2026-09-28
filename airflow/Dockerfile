FROM python:3.13

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Создаем пользователя
RUN useradd -ms /bin/bash airflow
WORKDIR /opt/airflow

USER root
# Копируем и ставим зависимости
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# Меняем владельца и переключаемся на пользователя
RUN chown -R airflow: /opt/airflow
USER airflow