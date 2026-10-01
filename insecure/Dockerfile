FROM python:3.12
WORKDIR /app
COPY . .
RUN pip install -r insecure/requirements.txt
EXPOSE 5000
CMD ["python", "insecure/app.py"]
