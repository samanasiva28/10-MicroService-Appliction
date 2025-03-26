# Use a multi-stage build to optimize image size
FROM golang:1.21.3-alpine@sha256:926f7f7e1ab8509b4e91d5ec6d5916ebb45155b0c8920291ba9f361d65385806 as builder
RUN apk add --no-cache ca-certificates git
WORKDIR /src

# Restore dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy application source code
COPY . .

# Skaffold passes in debug-oriented compiler flags
ARG SKAFFOLD_GO_GCFLAGS
RUN go build -gcflags="${SKAFFOLD_GO_GCFLAGS:-}" -o /go/bin/frontend .

# Final runtime image
FROM alpine:3.18.4@sha256:eece025e432126ce23f223450a0326fbebde39cdf496a85d8c016293fc851978 as release
RUN apk add --no-cache ca-certificates busybox-extras net-tools bind-tools
WORKDIR /src

# Copy compiled binary and static files
COPY --from=builder /go/bin/frontend /src/server
COPY ./templates ./templates
COPY ./static ./static

# Configure runtime environment
ENV GOTRACEBACK=single
EXPOSE 8080

# Start application
ENTRYPOINT ["/src/server"]
