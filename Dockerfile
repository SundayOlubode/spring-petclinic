FROM maven:3.8.5-openjdk-17 AS build
LABEL stage=builder

# Set working dir
WORKDIR /app

# Copy project files
COPY pom.xml .
COPY src ./src

RUN mvn clean install -DskipTests

FROM eclipse-temurin:17-jre-focal

# Non-root user and group
RUN groupadd --system petclinic && useradd --system --gid petclinic petclinic

# Working dir for non-root user
WORKDIR /app

# Copy the built JAR from the 'build' stage
COPY --from=build /app/target/*.jar app.jar

# Change app dir ownership to non-root user
RUN chown -R petclinic:petclinic /app

# Switch to non-root user
USER petclinic

# Expose the port the application runs on
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

