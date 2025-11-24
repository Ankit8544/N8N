# Use official n8n image as base
FROM n8nio/n8n:latest

USER root
RUN apt-get update && apt-get install -y python3 python3-pip curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

COPY app.py ./
COPY start.sh ./
RUN chmod +x start.sh

# Create directory used for persistent user folder (can be mounted to /data on Render)
RUN mkdir -p /data/.n8n && chown -R node:node /data

EXPOSE 5678

CMD ["/usr/src/app/start.sh"]
