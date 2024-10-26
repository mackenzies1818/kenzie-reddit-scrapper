FROM --platform=linux/amd64 python:3.9
WORKDIR /app
COPY .env /app/
COPY producer/ /app/
ENV ENV=prod
RUN pip install  --no-cache-dir -r requirements.txt
CMD ["python3", "producer.py"]

