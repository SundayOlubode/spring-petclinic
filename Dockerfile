# Stage 1: Build the application using Maven
FROM maven:3.8.5-openjdk-17 AS build
LABEL stage=builder

# Set the working directory
WORKDIR /app

# Copy the Maven project files
COPY pom.xml .
COPY src ./src

# Build the application, skipping tests to speed up the process for containerization
# The final JAR will be created in the 'target' directory
RUN mvn clean install -DskipTests

# Stage 2: Create the final, lightweight runtime image
# Using a different base image known for broad platform compatibility to resolve pull errors.
FROM eclipse-temurin:17-jre-focal

# Define a non-root user and group (Debian-based syntax)
RUN groupadd --system petclinic && useradd --system --gid petclinic petclinic

# Set the working directory for the non-root user
WORKDIR /app

# Copy the built JAR from the 'build' stage
COPY --from=build /app/target/*.jar app.jar

# Change ownership of the app directory and JAR file to the non-root user
RUN chown -R petclinic:petclinic /app

# Switch to the non-root user
USER petclinic

# Expose the port the application runs on
EXPOSE 8080

# Command to run the application
# The java command is executed when the container starts
ENTRYPOINT ["java", "-jar", "app.jar"]

