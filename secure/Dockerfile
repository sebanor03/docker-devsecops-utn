FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /app
COPY secure/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt \
    && useradd --create-home --uid 10001 appuser \
    && chown appuser:appuser /app
COPY --chown=appuser:appuser secure/app.py ./app.py
USER appuser
EXPOSE 5000
CMD ["python", "app.py"]
