FROM adoptopenjdk/openjdk8:alpine-slim

# Expose the application port
EXPOSE 8080

# Define the location of the JAR file
ARG JAR_FILE=target/*.jar

# Create a user and group
RUN addgroup -S pipeline && adduser -S k8s-pipeline -G pipeline

# Copy the JAR file to the desired location
COPY ${JAR_FILE} /home/k8s-pipeline/app.jar

# Switch to the new user
USER k8s-pipeline

# Set the working directory
WORKDIR /home/k8s-pipeline

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
