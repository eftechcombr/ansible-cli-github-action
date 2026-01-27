FROM python:3.11-slim

COPY requirements.txt .

RUN pip install --no-cache-dir --root-user-action=ignore -r requirements.txt

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["ansible-playbook", "main.yaml"] 

