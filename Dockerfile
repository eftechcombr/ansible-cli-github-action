FROM python:3-slim

WORKDIR /usr/src/app

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

ENTRYPOINT [ "sh", "-c" ]
# (Optional) Set the default command to run when the container starts
CMD ["ansible-playbook", "main.yaml"] 

