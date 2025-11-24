# Use official n8n image as base
FROM n8nio/n8n:latest

USER root
RUN apt-get update && apt-get install -y python3 python3-pip curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

# Python deps for the Flask proxy
COPY requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

COPY app.py ./
COPY start.sh ./
RUN chmod +x start.sh

# Expose n8n internal port for local debugging (not required on Render)
EXPOSE 5678

# Run wrapper which launches n8n and the Flask proxy
CMD ["/usr/src/app/start.sh"]
