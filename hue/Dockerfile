FROM gethue/hue:latest

# Устанавливаем зависимости
RUN /usr/share/hue/build/env/bin/pip install trino psycopg2-binary

# Создаём скрипт запуска ОТ ИМЕНИ ROOT, чтобы иметь права на запись
USER root
RUN printf '#!/bin/bash\n\
/usr/share/hue/build/env/bin/hue makemigrations --merge --noinput 2>/dev/null || true\n\
/usr/share/hue/build/env/bin/hue migrate --noinput 2>/dev/null || true\n\
exec /usr/share/hue/build/env/bin/hue runserver 0.0.0.0:8888\n' > /usr/local/bin/hue-start.sh && \
    chmod +x /usr/local/bin/hue-start.sh
# Возвращаем обычного пользователя (как в оригинальном образе)
USER hue

# Запускаем наш скрипт
CMD ["/usr/local/bin/hue-start.sh"]
