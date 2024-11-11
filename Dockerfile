FROM --platform=linux/amd64 992382748278.dkr.ecr.us-east-1.amazonaws.com/python_ecr_repo:3.9
WORKDIR /app
COPY .env /app/
COPY producer/ /app/
ENV ENV=prod
RUN pip install  --no-cache-dir -r requirements.txt
CMD ["python3", "producer.py"]

