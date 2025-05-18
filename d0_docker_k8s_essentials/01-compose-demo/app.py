import os
import time
import logging
from logging.config import dictConfig

import redis
from flask import Flask, jsonify

# Configure logging
dictConfig({
    'version': 1,
    'formatters': {'default': {
        'format': '[%(asctime)s] %(levelname)s in %(module)s: %(message)s',
    }},
    'handlers': {'wsgi': {
        'class': 'logging.StreamHandler',
        'stream': 'ext://sys.stdout',
        'formatter': 'default'
    }},
    'root': {
        'level': 'INFO',
        'handlers': ['wsgi']
    }
})

# Initialize Flask app
app = Flask(__name__)

# Configuration
REDIS_HOST = os.getenv('REDIS_HOST', 'redis')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
REDIS_RETRY_COUNT = int(os.getenv('REDIS_RETRY_COUNT', 5))
REDIS_RETRY_DELAY = float(os.getenv('REDIS_RETRY_DELAY', 0.5))

# Initialize Redis connection
cache = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    decode_responses=True  # Automatically decode responses to Python strings
)

def get_hit_count():
    retries = REDIS_RETRY_COUNT
    while True:
        try:
            return cache.incr('hits')
        except redis.exceptions.ConnectionError as exc:
            if retries == 0:
                app.logger.error(f"Failed to connect to Redis after {REDIS_RETRY_COUNT} attempts")
                raise exc
            retries -= 1
            app.logger.warning(f"Redis connection failed. Retrying... ({retries} attempts left)")
            time.sleep(REDIS_RETRY_DELAY)

@app.route('/')
def hello():
    try:
        count = get_hit_count()
        app.logger.info(f"Visitor count incremented to {count}")
        return f'Hello students! I have been seen {count} times.\n'
    except Exception as e:
        app.logger.error(f"Error processing request: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/health')
def health():
    try:
        # Check Redis connection
        cache.ping()
        return jsonify({"status": "healthy", "redis": "connected"}), 200
    except redis.exceptions.ConnectionError:
        return jsonify({
            "status": "unhealthy",
            "redis": "disconnected"
        }), 503

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)