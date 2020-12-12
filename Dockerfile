FROM yyoshiki41/radigo

RUN apk add --no-cache python3

VOLUME ["/data", "/config.json"]
WORKDIR /tmp

COPY rec.py /

# COPY entrypoint.sh /
ENTRYPOINT ["python3", "/rec.py"]
