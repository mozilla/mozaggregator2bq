FROM gcr.io/google.com/cloudsdktool/cloud-sdk

RUN apt update && apt -y install jq postgresql

WORKDIR /app

# check if dependencies change, otherwise reuse layers
COPY requirements.txt .
RUN pip3 install -r requirements.txt

ADD . .
