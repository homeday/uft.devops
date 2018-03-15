docker run -d \
    --restart always \
    -v /src:/src \
    --name opengrokcodeupdate \
    "opengrokcodeupdate:1.0" 