#!/bin/bash

echo "Before: PATH=$PATH" >> before.txt

if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    PATH=$(echo "$PATH" | sed "s|$HOME/.local/bin:||g")
    echo "Removed $HOME/.local/bin from PATH"
fi

echo "After: PATH=$PATH" >> after.txt

if grep -q 'export PATH="$PATH"' ~/.bashrc; then
    sed -i 's/^export PATH="$PATH"$/export PATH="$PATH"/' ~/.bashrc
    echo 'Overwrote existing export PATH="$PATH" in ~/.bashrc'
else
    echo 'export PATH="$PATH"' >> ~/.bashrc
    echo 'Added export PATH="$PATH" to ~/.bashrc'
fi

source ~/.bashrc
