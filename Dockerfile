FROM python:3.11-slim

WORKDIR /app
COPY src/cluster_audit/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/cluster_audit /app
ENV OUT_DIR=/output
RUN mkdir -p /output

ENTRYPOINT ["python", "/app/cluster_audit.py"]
