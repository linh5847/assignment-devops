# DEVOPS Assignment

This assignment consists of three scenarios that test your DevOps skills in CI/CD, Infrastructure as Code (Terraform), and local AWS emulation.

### ⚠️ IMPORTANT

- All tasks must run fully locally.
- Use Docker wherever possible.
- Use LocalStack for AWS services (no real AWS usage).
- Provide evidence (logs, screenshots, coverage reports, or terminal output).

### 📌 Task 01: Spring Boot + CI/CD Pipeline + Test Coverage

#### Goal

- Use the Spring Boot project provided in this repository.
- The project already has a sample /order endpoint that returns dummy order JSON (OrderResponse list).
- Your task is to:
  - Configure Jacoco to enforce a minimum test coverage of 80%.
  - Create a pipeline (Jenkins or GitHub Actions) that will:
    - Build the project
    - Run tests with coverage check
    - Fail the build if coverage is below 80%
- All of this must run locally using Docker (no requirement to install Java/Maven manually).

#### Requirements

- Use Maven or Gradle with Jacoco.
- Run everything in Docker so no local dependencies are required.
- Pipeline can be implemented with:
  - Jenkins (Jenkinsfile), or
  - GitHub Actions (.github/workflows/ci.yml)

#### Evidence

- Screenshot of Jacoco coverage report showing ≥ 80%.
- Screenshot/logs showing pipeline failure when coverage is below threshold.


### 📌 Task 02: API Gateway with Terraform (LocalStack)

#### Goal

- Create an API Gateway using Terraform.
- Add endpoint /order that returns a dummy order object (For example OrderResponse).
- Must run locally on LocalStack.

#### Requirements

- Provision API Gateway with Terraform.
- Use Dockerized LocalStack (no AWS account).

#### Evidence

- Screenshot of terraform apply output.
- Screenshot of successful curl response returning dummy order JSON.


### 📌 Task 03: JWT Authorizer Lambda with Terraform (LocalStack)

#### Goal

- Create an API Gateway Authorizer Lambda with Terraform.
- Request comes with JWT token:
    - Use this sample token
      - eyJraWQiOiI0YzRiNWU4ZS0xMDg0LTRlNmQtOGQ0OC0xMTk2MjIzMmE5MjMiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbkBmeWFvcmEuY29tIiwiYXVkIjoiZnlhb3JhIiwibmJmIjoxNzU5Mjc3NjA4LCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwicm9sZXMiOlsiUk9MRV9GWUFPUkFfQURNSU4iLCJST0xFX0ZZQU9SQV9VU0VSIl0sImlzcyI6Imh0dHA6Ly8xMDcuMjIuMTM1LjE5NDo5MDgwIiwiZXhwIjoxNzU5MjgxMjA4LCJpYXQiOjE3NTkyNzc2MDgsImp0aSI6Ijg2ZWI4ZDlkLTBlMWQtNGE4MC1hMTI1LWU2MjBjNWYzNTBkMyIsImF1dGhvcml0aWVzIjpbIlJPTEVfRllBT1JBX0FETUlOIiwiUk9MRV9GWUFPUkFfVVNFUiJdfQ.H2yJ-e91b5scaYo66w43CCAAalFHDezlIzD5ghz_mF-rQ-2m1dzcHtkdh8fEBxH8aZ_k3XTzjGW9ynnPl_LXWjRE9GUeWs6L-IIp66-FDj7miAN-UBJrkFSrmzoYSG8XePiej7lFwnYC7Vk2cFlOLH7uyaKb3YWdadiVmDjyU2QcDrRy49J_x1PbVZA6I5bXQft9otyTFxin5y3G7nMzXuOv2Dt5jOxwjMk3BU6jxW7O44F9jM3aVjhQQb90-B8bRgr2kIZEOTf7IDbVmlNTC4_y9bulbrmDyljg-i46K8kMwB3cnNDqd2e6yGzSvhZ02YNNElzZoEvMmKMzT_71VA
    - If invalid → return 400 Bad Request.
    - If valid → return 200 OK.
- Must run on LocalStack.

#### Requirements

- Implement Authorizer Lambda (e.g., in java/Python/Node.js).
- Deploy using Terraform to LocalStack.
- Validate JWT with a hardcoded secret/public key (no Cognito).

#### Evidence

- Screenshot of Terraform deployment logs.
- Screenshot/logs showing:
  - 200 OK for valid JWT
  - 400 Bad Request for invalid JWT