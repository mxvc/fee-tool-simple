# 阶段1 前端构建
FROM node:16-alpine as web
ADD asserts/.npmrc  /root/

WORKDIR /temp

# 缓存包

ADD web/package.json .
RUN npm install


# 正式打包
ADD web/ ./
RUN npm run build

# 阶段2 打jar包
FROM maven:3-openjdk-17 as java
ADD asserts/settings.xml /root/.m2/

# 缓存jar包
WORKDIR /temp
ADD pom.xml ./pom.xml
ADD src/main/java/cn/moon/BootApplication.java ./src/main/java/cn/crec/BootApplication.java

RUN mvn  package -q -DskipTests=true  &&  rm -rf *

# 正式打包
ADD src ./src
ADD pom.xml ./pom.xml
COPY --from=web /temp/dist/ src/main/resources/static/


RUN mvn clean  package -q  -DskipTests=true &&  mv target/app.jar /home/app.jar &&   rm -rf *

# 阶段3 运行环境
FROM openjdk:17

COPY --from=java /home/app.jar /home/app.jar


ENTRYPOINT java \
                # 随机数
                -Djava.security.egd=file:/dev/./urandom \
                # 时区
                -Duser.timezone=Asia/Shanghai \
                -jar /home/app.jar \
                --spring.profiles.active=prod