#!/bin/bash

function newproj {
    org="$1"
    proj="$2"
    src="/opengrok/src/$proj"
    # if project folder exists, skip
    if [ -d "$src" ]; then return 0; fi

    "/opengrok/scripts/new-proj.sh" "$org" "$proj"
}

newproj uft uftbase
newproj uft st
newproj uft sprinter

newproj uft qtp.addins.resources
newproj uft qtp.devutils
newproj uft qtp.addins.core
newproj uft qtp.addins.te
newproj uft qtp.doc
newproj uft qtp.addins.dotnet
newproj uft qtp.addins.teabased
newproj uft qtp.frontend
newproj uft qtp.addins.erp
newproj uft qtp.addins.uiautomation
newproj uft qtp.infra
newproj uft qtp.addins.flash
newproj uft qtp.addins.webbased
newproj uft qtp.mlu
newproj uft qtp.addins.iba
newproj uft qtp.addins.webservices
newproj uft qtp.services
newproj uft qtp.addins.java
newproj uft qtp.addins.winbased
newproj uft qtp.services.utils
newproj uft qtp.addins.metro
newproj uft qtp.backend
newproj uft qtp.setup
newproj uft qtp.addins.mobile
newproj uft qtp.build
newproj uft qtp.addins.qtcustsupport
newproj uft qtp.addins.pdf
newproj uft qtp.components
newproj uft qtp.addins.ai
