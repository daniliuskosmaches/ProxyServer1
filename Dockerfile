FROM ubuntu:latest
LABEL authors="nazar"

ENTRYPOINT ["top", "-b"]
FROM maven:3.9.5-eclipse-temurin-25 AS builder

# Устанавливаем рабочую директорию в контейнере
WORKDIR /app

# Копируем pom.xml и скачиваем зависимости
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Копируем весь исходный код и собираем приложение
COPY src ./src
RUN mvn package -DskipTests

# ====================================================================
# СТАДИЯ 2: Запуск (RUNNER STAGE)
# Используем минимальный образ с JRE 25 для запуска
# ====================================================================
FROM eclipse-temurin:25-jre-alpine

# Аргумент для имени JAR-файла (если оно меняется)
ARG JAR_FILE=target/*.jar

# Копируем ТОЛЬКО готовый JAR-файл из первой стадии (builder)
COPY --from=builder /app/${JAR_FILE} app.jar

# Устанавливаем стандартный порт Spring Boot
EXPOSE 8080

# Точка входа: команда, которая запускает приложение
ENTRYPOINT ["java", "-jar", "/app.jar"]