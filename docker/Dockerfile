FROM public.ecr.aws/docker/library/python:3.9
WORKDIR /app
COPY .env /app/
COPY src/producer.py /app/producer.py
COPY src/requirements.txt /app/requirements.txt
ENV ENV=prod
RUN pip install  --no-cache-dir -r requirements.txt
CMD ["python3", "producer.py"]

