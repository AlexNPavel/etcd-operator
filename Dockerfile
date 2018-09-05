FROM openshift/origin-base as builder
RUN yum update -y
RUN yum install -y golang git

RUN curl -L https://github.com/golang/dep/releases/download/v0.4.1/dep-linux-amd64 -o /usr/local/bin/dep \
    && chmod +x /usr/local/bin/dep \
    && go get honnef.co/go/tools/cmd/gosimple \
    && go get honnef.co/go/tools/cmd/unused

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

WORKDIR /go/src/github.com/coreos/etcd-operator
COPY . .

RUN dep ensure
RUN /bin/bash -c "hack/build/operator/build && hack/build/backup-operator/build && hack/build/restore-operator/build"

FROM openshift/origin-base
# Copy the binary to a standard location where it will run.
COPY --from=builder /go/src/github.com/coreos/etcd-operator/_output/bin/etcd-backup-operator /usr/local/bin/etcd-backup-operator
COPY --from=builder /go/src/github.com/coreos/etcd-operator/_output/bin/etcd-restore-operator /usr/local/bin/etcd-restore-operator
COPY --from=builder /go/src/github.com/coreos/etcd-operator/_output/bin/etcd-operator /usr/local/bin/etcd-operator

USER 1001

LABEL io.k8s.display-name="Etcd Operator" \
      io.k8s.description="The etcd operator manages etcd clusters deployed to Kubernetes and automates tasks related to operating an etcd cluster." \
      maintainer="Etcd Authors..."