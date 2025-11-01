# ====================================================================
# СТАДИЯ 1: Сборка (BUILDER STAGE)
# Используем чистый JDK 25 и устанавливаем Maven вручную
# ====================================================================
FROM eclipse-temurin:25-jdk-alpine AS builder

# Установим Maven (потребуются wget и unzip)
RUN apk add --no-cache wget unzip bash
ARG MAVEN_VERSION=3.9.5
ARG MAVEN_HOME=/usr/share/maven
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.zip

# Скачиваем, разархивируем и настраиваем Maven
RUN wget -q ${BASE_URL} -O /tmp/maven.zip \
    && unzip -q /tmp/maven.zip -d /usr/share \
    && mv /usr/share/apache-maven-${MAVEN_VERSION} ${MAVEN_HOME} \
    && ln -s ${MAVEN_HOME}/bin/mvn /usr/bin/mvn \
    && rm /tmp/maven.zip

# Настраиваем переменные окружения
ENV MAVEN_HOME ${MAVEN_HOME}
ENV PATH $PATH:$MAVEN_HOME/bin

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
# Используем минимальный JRE 25
# ====================================================================
FROM eclipse-temurin:25-jre-alpine

# Аргумент для имени JAR-файла
ARG JAR_FILE=target/*.jar

# Копируем ТОЛЬКО готовый JAR-файл из первой стадии (builder)
COPY --from=builder /app/${JAR_FILE} app.jar

# Устанавливаем стандартный порт Spring Boot
EXPOSE 8080

# Точка входа
ENTRYPOINT ["java", "-jar", "/app.jar"]