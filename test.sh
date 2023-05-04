#!/bin/bash

if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    export PATH=${PATH//$HOME\/.local\/bin:/}
    if ! grep -q 'export PATH="$PATH"' ~/.bashrc; then
        echo 'export PATH="$PATH"' >> ~/.bashrc
        echo 'Added export PATH="$PATH" to ~/.bashrc'
    fi
    source ~/.bashrc
fi

