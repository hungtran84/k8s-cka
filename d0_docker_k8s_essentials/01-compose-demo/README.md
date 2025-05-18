# Docker Compose Demo

This demo showcases a simple Flask application with Redis backend using Docker Compose for orchestration.

## Prerequisites

- Docker Engine installed on your machine
- Docker Compose V2 installed
- Basic understanding of Python and Docker concepts

## Architecture

The application consists of two services:
- A Flask web application that counts visitor hits
- A Redis backend for storing the hit counter

## Getting Started

### Option 1: Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/hungtran84/k8s-cka.git
   cd k8s-cka/d0_docker_k8s_essentials/01-compose-demo
   ```

2. Start the application:
   ```bash
   docker compose up -d
   ```

3. Access the application at http://localhost:8000

### Option 2: Using Docker Playground

1. Create a Docker account at [Docker Signup](https://hub.docker.com/signup) if you haven't already.

2. Visit [Play-with-Docker](https://labs.play-with-docker.com) and log in.

3. Click "Add New Instance" to create a new playground environment.

4. Follow the same steps as local development to clone and run the application.

## Development Workflow

### Making Changes

The application uses volume mounting for development, so any changes to the Python code will be reflected immediately:

1. Modify the application code:
   ```bash
   # Example: Change the greeting message
   sed -i 's/students/developers/g' app.py
   ```

2. The changes will be automatically detected and the application will reload.

### Viewing Logs

```bash
# View logs from all services
docker compose logs

# View logs from specific service
docker compose logs web
docker compose logs redis

# Follow logs in real-time
docker compose logs -f
```

### Scaling the Application

```bash
# Scale the web service
docker compose up -d --scale web=3
```

## Troubleshooting

Common issues and their solutions:

1. If Redis connection fails:
   - Check if Redis container is running: `docker compose ps`
   - Verify network connectivity: `docker compose exec web ping redis`

2. If the web application is not accessible:
   - Verify port mapping: `docker compose ps`
   - Check container logs: `docker compose logs web`

## Cleanup

To stop and remove all containers:
```bash
docker compose down
```

To also remove volumes:
```bash
docker compose down -v
```

## Additional Resources

- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Flask documentation](https://flask.palletsprojects.com/)
- [Redis documentation](https://redis.io/documentation)
