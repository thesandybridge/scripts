#!/bin/bash

if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    export PATH=${PATH//$HOME\/.local\/bin:/}
    echo 'export PATH="$PATH"' >> ~/.bashrc
    source ~/.bashrc
fi

