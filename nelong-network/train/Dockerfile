FROM python:3.10-slim

RUN pip install cryptography flask

WORKDIR /app
COPY . /app

CMD ["python", "enclave_server.py"]


