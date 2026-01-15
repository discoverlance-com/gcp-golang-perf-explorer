
FROM golang:1.23 AS builder

WORKDIR /app
COPY . .

RUN go mod download

# Build the binary.
# -mod=readonly ensures immutable go.mod
RUN CGO_ENABLED=0 GOOS=linux go build -mod=readonly -v -o server

FROM gcr.io/distroless/static-debian12


COPY --from=builder /app/server /server
COPY --from=builder /app/templates /templates

# Run the web service on container startup.
CMD ["/server"]
