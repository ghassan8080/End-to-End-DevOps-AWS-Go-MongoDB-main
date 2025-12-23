FROM golang:1.21-alpine3.19

WORKDIR /app

COPY . .

RUN go mod download && \
  go mod verify && \
  go build -o survey .

CMD [ "./survey" ]

EXPOSE 8080
