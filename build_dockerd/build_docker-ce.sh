#!/bin/bash
test_cmd()
{
    $1 &>/dev/null
    if [ "$?" != "0" ];then
        echo "Error: $2"
        exit
    fi
}
env_init()
{
    ARCH=$1
    DOCKER_VERSION=v19.03.13
    
    if [ ! -d docker-ce ];then
        git clone https://github.com/docker/docker-ce
        git -C docker-ce checkout $DOCKER_VERSION
    fi
    
    
    if [ "$ARCH" = "arm64" ];then
        GOARCH=arm64
        CROSS_COMPILE=aarch64-linux-gnu-
        CC=${CROSS_COMPILE}gcc
        test_cmd "$CC -v" "$CC not found"
    else
        #x86
        GOARCH=amd64
        CC=gcc
        test_cmd "$CC -v" "$CC not found"
    fi
    test_cmd "go version" "go not found"
    
    PREFIX=$PWD/bin.${GOARCH}
    mkdir -p $PREFIX
    #go
    ORG_GOPATH=`go env GOPATH`
    ORG_GOARCH=`go env GOARCH`
    GOPATH=$PWD/go
    go env -w GOPATH=$GOPATH
    #go env -w GOARCH=$GOARCH
    export GOARCH GOOS=linux PREFIX GOPATH CC
    echo "$GOARCH $GOOS $PREFIX $GOPATH $CC"
    
}
env_rollback()
{
    [ "$ORG_GOPATH" != "" ] && go env -w GOPATH=$ORG_GOPATH
    [ "$ORG_GOARCH" != "" ] && go env -w GOARCH=$ORG_GOARCH
}

build_dockercli()
{
    echo "build docker-cli"
    
    if [ ! -d $GOPATH/src/github.com/docker/cli/cmd/docker ];then
        echo "go get -d github.com/docker/cli/cmd/docker"
        go get -d github.com/docker/cli/cmd/docker
    fi
    
    (
        cd components/cli/
        ./scripts/build/binary
        cp build/docker-linux-$GOARCH $PREFIX/docker
    )
}
build_runc()
{
    echo "build runc"
    (
        export RUNC_BUILDTAGS=' '
        cd components/engine/ && . ./hack/dockerfile/install/runc.installer && install_runc
    )
}
build_tinit()
{
    echo "build docker-init"
    [ -d $GOPATH/tini ] && rm -rf $GOPATH/tini/CMakeCache.txt $GOPATH/tini/CMakeFiles
    (
        cd components/engine/
        . ./hack/dockerfile/install/tini.installer
        install_tini
    )
}
#copy from engine/hack/dockerfile/install/containerd.installer
build_my_containerd()
{
    if [ ! -d $GOPATH/src/github.com/containerd/containerd ];then
        . components/engine/hack/dockerfile/install/containerd.installer
        echo "Install containerd version $CONTAINERD_COMMIT"
        git clone https://github.com/containerd/containerd.git "$GOPATH/src/github.com/containerd/containerd"
        #cd "$GOPATH/src/github.com/containerd/containerd"
        git -C $GOPATH/src/github.com/containerd/containerd checkout -q "$CONTAINERD_COMMIT"
        #patch for compile
        sed -i "s/GO_GCFLAGS +/#GO_GCFLAGS +/g" $GOPATH/src/github.com/containerd/containerd/Makefile.linux
    fi

    (
        echo "build containerd"
        cd "$GOPATH/src/github.com/containerd/containerd"
        export BUILDTAGS='netgo osusergo static_build no_btrfs'
        #export EXTRA_FLAGS='-buildmode=pie'
        export EXTRA_FLAGS=''
        export EXTRA_LDFLAGS='-extldflags "-fno-PIC -static"'
        make
        mkdir -p "${PREFIX}"
        echo "copy to ${PREFIX}/"
        cp bin/* "${PREFIX}/"
        #ln -sf containerd-shim-runc-v1 ${PREFIX}/containerd-shim-runc-v2
    )

    
}
build_dockerd()
{
    if [ ! -d $GOPATH/src/github.com/docker/docker/cmd/dockerd ];then
        echo "go get -d github.com/docker/docker/cmd/dockerd"
        go get -d github.com/docker/docker/cmd/dockerd
    fi
    rm -rf $GOPATH/src/github.com/docker/docker/dockerversion
    ln -sf $PWD/components/engine/dockerversion $GOPATH/src/github.com/docker/docker/dockerversion
    echo "build dockerd"
     ( 
        cd components/engine/
        export DOCKER_GITCOMMIT="$DOCKER_VERSION"
        ./hack/make.sh binary
        cp bundles/binary-daemon/dockerd-dev ${PREFIX}/dockerd
     )
}
env_init $@
cd docker-ce
build_dockercli
build_runc
build_tinit
build_my_containerd
build_dockerd
file $PREFIX/*
ls -alh $PREFIX/*
env_rollback

