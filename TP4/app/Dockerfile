RUN apt update -y && \
    apt install -y wget && \
    apt install -y tar

RUN wget https://go.dev/dl/go1.19.3.linux-amd64.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf go1.19.3.linux-amd64.tar.gz

COPY hangman-web /app/hangman-web

WORKDIR /app/hangman-web/hangman

CMD [ "/usr/local/go/bin/go", "run", "main.go" ]